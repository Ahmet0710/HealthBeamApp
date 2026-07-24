// In: MealHistoryView.swift
import SwiftUI
import SwiftData
struct MealHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext // Silme işlemi için eklenebilir
    @EnvironmentObject private var achievementsViewModel: AchievementsViewModel
    @Query(sort: \Meal.time, order: .reverse) private var allMeals: [Meal]
    private var groupedMeals: [Date: [Meal]] {
        Dictionary(grouping: allMeals) { meal in
            Calendar.current.startOfDay(for: meal.time)
        }
    }

    private var sortedDateKeys: [Date] {
        groupedMeals.keys.sorted(by: >)
    }

    var body: some View {
        NavigationStack {
            Group {
                if allMeals.isEmpty {
                    ContentUnavailableView("No Meal History", systemImage: "fork.knife.circle", description: Text("When you log meals, they will appear here."))
                } else {
                    List {
                        ForEach(sortedDateKeys, id: \.self) { date in
                            Section(header: Text(formatDateHeader(date))) {
                                ForEach(groupedMeals[date] ?? []) { meal in
                                    MealRowHistory(meal: meal)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Meal History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
private struct MealRowHistory: View {
    let meal: Meal
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(meal.name).font(.headline).lineLimit(1)
                    Text("\(meal.mealType.rawValue) at \(timeFormatter.string(from: meal.time))")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text("\(Int(meal.calories)) kcal").font(.headline.weight(.semibold))
            }
            HStack {
                NutritionInfoView(value: Int(meal.protein), label: "Protein", color: .pink)
                NutritionInfoView(value: Int(meal.carbs), label: "Carbs", color: .teal)
                NutritionInfoView(value: Int(meal.fat), label: "Fat", color: .orange)
                if meal.sugar > 0 {
                    NutritionInfoView(value: Int(meal.sugar), label: "Sugar", color: .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

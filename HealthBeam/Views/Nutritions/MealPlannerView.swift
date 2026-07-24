import SwiftUI
import SwiftData
private struct PlanningSheetItem: Identifiable {
    let id: String
    let date: Date
    let mealType: MealType
    var plan: MealPlan?
    init(date: Date, mealType: MealType, plan: MealPlan? = nil) {
        self.id = "\(date.timeIntervalSince1970)-\(mealType.rawValue)"
        self.date = date
        self.mealType = mealType
        self.plan = plan
    }
}
struct MealPlannerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var achievementsViewModel: AchievementsViewModel

    @Query(sort: \MealPlan.date) private var mealPlans: [MealPlan]

    @State private var weekToShow: Date = Date()
    @State private var planningSheetItem: PlanningSheetItem?

    private var weekDays: [Date] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: weekToShow) else { return [] }
        var days: [Date] = []
        for i in 0..<7 {
            if let day = Calendar.current.date(byAdding: .day, value: i, to: weekInterval.start) {
                days.append(day)
            }
        }
        return days
    }

    var body: some View {
           NavigationStack {
               ScrollView {
                   VStack(spacing: 0) {
                       WeekDateNavigator(date: $weekToShow)
                           .padding()
                           .background(.bar)

                       VStack(spacing: 16) {
                           ForEach(weekDays, id: \.self) { day in
                               DailyPlanCardView(
                                   day: day,
                                   plans: mealPlans.filter { Calendar.current.isDate($0.date, inSameDayAs: day) },
                                   onSlotTapped: { mealType, plan in
                                       planningSheetItem = PlanningSheetItem(date: day, mealType: mealType, plan: plan)
                                   }
                               )
                           }
                       }
                       .padding()
                   }
               }
               .background(Color(.systemGroupedBackground))
               .navigationTitle("Meal Planner")
               .navigationBarTitleDisplayMode(.inline)
               .toolbar {
                   ToolbarItem(placement: .cancellationAction) {
                       Button("Dismiss") { dismiss() }
                   }
               }
               .sheet(item: $planningSheetItem) { item in
                   PlanMealSheet(item: item)
               }
           }
       }
   }
private struct DailyPlanCardView: View {
    let day: Date
    let plans: [MealPlan]
    let onSlotTapped: (MealType, MealPlan?) -> Void

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    private var isPastDate: Bool {
        Calendar.current.startOfDay(for: day) < Calendar.current.startOfDay(for: Date())
    }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }

    private var numberFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "d MMMM"
        return f
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(dayFormatter.string(from: day))
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(numberFormatter.string(from: day))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .foregroundColor(isToday ? .blue : .primary)

            MealPlanSlotView(
                day: day,
                mealType: .breakfast,
                plan: plans.first { $0.mealType == .breakfast },
                onTapped: onSlotTapped
            )
            MealPlanSlotView(
                day: day,
                mealType: .lunch,
                plan: plans.first { $0.mealType == .lunch },
                onTapped: onSlotTapped
            )
            MealPlanSlotView(
                day: day,
                mealType: .dinner,
                plan: plans.first { $0.mealType == .dinner },
                onTapped: onSlotTapped
            )
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
        )
        .opacity(isPastDate ? 0.6 : 1.0)
    }
}
private struct MealPlanSlotView: View {
    let day: Date
    let mealType: MealType
    let plan: MealPlan?
    let onTapped: (MealType, MealPlan?) -> Void

    private var hasNote: Bool {
        if let notes = plan?.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
    }

    private var isPastDate: Bool {
        Calendar.current.startOfDay(for: day) < Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        Button(action: { onTapped(mealType, plan) }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mealType.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let plan = plan, !plan.plannedMealName.isEmpty {
                        Text(plan.plannedMealName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    } else {
                        Text(isPastDate ? "Not Planned" : "Tap to Plan")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if hasNote {
                    Image(systemName: "note.text")
                        .foregroundColor(.secondary)
                }

                if !isPastDate {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundColor(.secondary.opacity(plan == nil && !isPastDate ? 0.2 : 0))
            )
        }
        .buttonStyle(.plain)
        .disabled(isPastDate)
    }
}
private struct WeekDateNavigator: View {
    @Binding var date: Date
    private var weekInterval: DateInterval? {
        Calendar.current.dateInterval(of: .weekOfYear, for: date)
    }

    private var title: String {
        guard let interval = weekInterval else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let startDate = formatter.string(from: interval.start)
        let endDate = formatter.string(from: interval.end.addingTimeInterval(-1))

        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        let year = yearFormatter.string(from: date)

        return "\(startDate) - \(endDate), \(year)"
    }

    var body: some View {
        HStack {
            Button {
                date = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: date) ?? date
            } label: { Image(systemName: "chevron.left.circle.fill") }

            Spacer()
            Text(title).font(.headline.bold())
            Spacer()

            Button {
                date = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
            } label: { Image(systemName: "chevron.right.circle.fill") }
        }
        .font(.title2)
        .foregroundColor(.secondary)
    }
}
private struct PlanMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var achievementsViewModel: AchievementsViewModel
    let item: PlanningSheetItem

    @State private var mealName: String
    @State private var notes: String

    init(item: PlanningSheetItem) {
        self.item = item
        _mealName = State(initialValue: item.plan?.plannedMealName ?? "")
        _notes = State(initialValue: item.plan?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal Details") {
                    TextField("Planned  Meal ", text: $mealName)
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("\(item.mealType.rawValue) Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Dismiss") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: savePlan) }
            }
        }
    }

    private func savePlan() {
        if let existingPlan = item.plan {
            existingPlan.plannedMealName = mealName
            existingPlan.notes = notes
        } else {
            let newPlan = MealPlan(date: item.date, mealType: item.mealType, plannedMealName: mealName, notes: notes)
            modelContext.insert(newPlan)
        }
        achievementsViewModel.markAchievementCompleted(id: "nutrition.meal_planner")
        dismiss()
    }
}

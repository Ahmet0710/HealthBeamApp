import SwiftUI
import HealthKit
import Combine
import SwiftData
import UIKit

private struct NutritionCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.62))
                    .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private extension View {
    func nutritionCardStyle() -> some View {
        modifier(NutritionCardStyle())
    }
}

struct NutritionView: View {
    @EnvironmentObject private var viewModel: NutritionViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.displayScale) private var displayScale
    @EnvironmentObject private var achievementsViewModel: AchievementsViewModel
    @EnvironmentObject private var measurementSystemManager: MeasurementSystemManager
    
    // SwiftData Query'si normal kullanıcılar için çalışmaya devam ediyor
    @Query(sort: \Meal.time, order: .reverse) private var allMeals: [Meal]
    
    @State private var mealToShare: Meal?
    @State private var sharedMealImage: UIImage?
    @State private var mealToEdit: Meal?
    @State private var isShowingShareSheet = false
    @State private var showingAddFood = false
    @State private var showingMealPlanner = false
    @State private var showingGoalSettings = false
    @State private var selectedMealType: MealType? = nil
    
    // MARK: - Veri Kaynağı Mantığı Değişikliği
    // Demo modundaysa Mock verileri, değilse SwiftData verilerini kullan
    private var todaysMeals: [Meal] {
        if AppReviewManager.shared.isDemoMode {
            return MockNutrition.sampleMeals
        }
        return allMeals.filter { Calendar.current.isDateInToday($0.time) }
    }

    private var filteredMeals: [Meal] {
        if let selectedType = selectedMealType {
            return todaysMeals.filter { $0.mealType == selectedType }
        }
        return todaysMeals
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        HeaderSummaryView(
                            todaysMeals: todaysMeals,
                            viewModel: viewModel,
                            selectedMealType: $selectedMealType,
                            onShowPlanner: { showingMealPlanner = true },
                            onShowGoalSettings: { showingGoalSettings = true },
                            measurementSystem: measurementSystemManager.measurementSystem
                        )
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Today's Meals")
                                        .font(.system(size: 23, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text(filteredMeals.isEmpty ? String(localized: "Nothing logged yet") : String(localized: "\(filteredMeals.count) entries for today"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }

                            if filteredMeals.isEmpty {
                                emptyStateView
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(filteredMeals) { meal in
                                        MealCardView(
                                            meal: meal,
                                            onDelete: { deleteMeal(meal) },
                                            onShare: { shareMeal(meal) },
                                            onEdit: { mealToEdit = meal }
                                        )
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .nutritionCardStyle()
                        .padding(.horizontal)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
            }
            .safeAreaPadding(.top, 8)
            .safeAreaInset(edge: .bottom) {
                nutritionActionInset
            }
            .sheet(isPresented: $showingAddFood) {
                NavigationStack { AddFoodView(allMeals: allMeals) }
            }
            .sheet(isPresented: $showingMealPlanner) {
                MealPlannerView()
            }
            .sheet(isPresented: $showingGoalSettings) {
                NutritionGoalSettingsView(viewModel: viewModel)
            }
            .sheet(item: $mealToEdit) { meal in
                EditMealView(meal: meal)
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let meal = mealToShare, let sharedMealImage {
                    ShareSheet(activityItems: [sharedMealImage, "Today's meal: \(meal.name) • \(Int(meal.calories)) kcal • Shared from HealthBeam"])
                }
            }
            .onAppear {
                viewModel.setup(achievementsViewModel: achievementsViewModel)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.green.opacity(0.24),
                    Color.black,
                    Color(red: 0.02, green: 0.05, blue: 0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.green.opacity(0.18))
                .blur(radius: 90)
                .frame(width: 280, height: 280)
                .offset(x: 120, y: -220)

            Circle()
                .fill(Color.teal.opacity(0.10))
                .blur(radius: 110)
                .frame(width: 320, height: 320)
                .offset(x: -130, y: 280)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Nutrition")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Track fuel, water, and balance for today.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }

    private var nutritionActionInset: some View {
        HStack {
            Spacer()
            fab
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private func deleteMeal(_ meal: Meal) {
        Task {
            await viewModel.deleteMeal(meal, modelContext: modelContext)
        }
    }

    private func shareMeal(_ meal: Meal) {
        mealToShare = meal
        sharedMealImage = renderShareImage(for: meal)
        isShowingShareSheet = sharedMealImage != nil
    }

    @MainActor
    private func renderShareImage(for meal: Meal) -> UIImage? {
        let renderer = ImageRenderer(content: MealShareView(meal: meal))
        renderer.scale = displayScale
        return renderer.uiImage
    }

    private var fab: some View {
        Button(action: { showingAddFood = true }) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 62, height: 62)
                .background(
                    Circle()
                        .fill(Color.green.opacity(0.25))
                        .background(Circle().fill(.ultraThinMaterial))
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        )
                )
                .clipShape(Circle())
                .shadow(color: .green.opacity(0.28), radius: 14, x: 0, y: 8)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 6) {
                Text(selectedMealType == nil ? String(localized: "No meals added today") : String(localized: "No entries for this meal type"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Tap the plus button to log your first meal or add water from the summary card.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}

// MARK: - Subviews

private struct WaterSummaryCardView: View {
    let currentIntake: Double
    let goal: Double
    let measurementSystem: MeasurementSystem
    private var progress: Double { goal > 0 ? min(1.0, currentIntake / goal) : 0 }

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: "drop.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Water tracking")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("\(measurementSystem.formatWater(currentIntake)) / \(measurementSystem.formatWater(goal))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 7)
                Circle().trim(from: 0, to: progress)
                    .stroke(Color.blue.gradient, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.85), value: progress)
            }
            .frame(width: 48, height: 48)
        }
        .padding(16)
        .nutritionCardStyle()
    }
}

private struct HeaderSummaryView: View {
    let todaysMeals: [Meal]
    @ObservedObject var viewModel: NutritionViewModel
    @Binding var selectedMealType: MealType?
    var onShowPlanner: () -> Void
    var onShowGoalSettings: () -> Void
    let measurementSystem: MeasurementSystem

    private var totalCaloriesToday: Double { viewModel.todayCaloriesFromHealthKit + todaysMeals.reduce(0) { $0 + $1.calories } }
    private var totalProteinToday: Double { viewModel.todayProteinFromHealthKit + todaysMeals.reduce(0) { $0 + $1.protein } }
    private var totalCarbsToday: Double { viewModel.todayCarbsFromHealthKit + todaysMeals.reduce(0) { $0 + $1.carbs } }
    private var totalFatToday: Double { viewModel.todayFatFromHealthKit + todaysMeals.reduce(0) { $0 + $1.fat } }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Summary")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Calories, macros, and hydration at a glance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onShowPlanner) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.green)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(Color.green.opacity(0.12))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                }

                Button(action: onShowGoalSettings) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                }
            }

            ViewThatFits(in: .horizontal) {
                wideSummaryLayout
                compactSummaryLayout
            }

            HStack(spacing: 0) {
                ForEach(MealType.allCases, id: \.id) { type in
                    MealTypeButton(type: type, isSelected: selectedMealType == type) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            selectedMealType = selectedMealType == type ? nil : type
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .nutritionCardStyle()
    }

    private var wideSummaryLayout: some View {
        HStack(alignment: .center, spacing: 16) {
            calorieRing

            VStack(spacing: 12) {
                waterCard

                HStack(spacing: 8) {
                    NutritionStatPill(title: "Protein", value: totalProteinToday, color: .pink)
                    NutritionStatPill(title: "Carbs", value: totalCarbsToday, color: .teal)
                    NutritionStatPill(title: "Fat", value: totalFatToday, color: .orange)
                }
            }
        }
    }

    private var compactSummaryLayout: some View {
        VStack(spacing: 14) {
            calorieRing
                .frame(maxWidth: .infinity)

            waterCard

            VStack(spacing: 8) {
                NutritionStatPill(title: "Protein", value: totalProteinToday, color: .pink)
                NutritionStatPill(title: "Carbs", value: totalCarbsToday, color: .teal)
                NutritionStatPill(title: "Fat", value: totalFatToday, color: .orange)
            }
        }
    }

    private var calorieRing: some View {
        CalorieRingView(
            progress: min(totalCaloriesToday / viewModel.dailyCalorieGoal, 1.0),
            consumedCalories: totalCaloriesToday,
            goalCalories: viewModel.dailyCalorieGoal,
            measurementSystem: measurementSystem
        )
    }

    private var waterCard: some View {
        NavigationLink(destination: WaterTrackerView().environmentObject(viewModel)) {
            WaterSummaryCardView(
                currentIntake: viewModel.todayWaterIntakeLiters,
                goal: viewModel.dailyWaterGoalLiters,
                measurementSystem: measurementSystem
            )
        }
        .buttonStyle(.plain)
    }
}

private struct NutritionGoalSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NutritionViewModel

    @State private var calorieGoal: Double
    @State private var proteinGoal: Double
    @State private var carbsGoal: Double
    @State private var fatGoal: Double
    @State private var waterGoal: Double

    init(viewModel: NutritionViewModel) {
        self.viewModel = viewModel
        _calorieGoal = State(initialValue: viewModel.dailyCalorieGoal)
        _proteinGoal = State(initialValue: viewModel.dailyProteinGoal)
        _carbsGoal = State(initialValue: viewModel.dailyCarbsGoal)
        _fatGoal = State(initialValue: viewModel.dailyFatGoal)
        _waterGoal = State(initialValue: viewModel.dailyWaterGoalLiters)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Goals") {
                    goalRow(title: String(localized: "Calories"), value: $calorieGoal, unit: "kcal")
                    goalRow(title: String(localized: "Protein"), value: $proteinGoal, unit: "g")
                    goalRow(title: String(localized: "Carbs"), value: $carbsGoal, unit: "g")
                    goalRow(title: String(localized: "Fat"), value: $fatGoal, unit: "g")
                    goalRow(title: String(localized: "Water"), value: $waterGoal, unit: "L")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationTitle("Nutrition Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateDailyGoals(
                            calories: max(0, calorieGoal),
                            protein: max(0, proteinGoal),
                            carbs: max(0, carbsGoal),
                            fat: max(0, fatGoal),
                            water: max(0, waterGoal)
                        )
                        dismiss()
                    }
                }
            }
        }
    }

    private func goalRow(title: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: value, format: .number.precision(.fractionLength(unit == "L" ? 1 : 0)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }
}

private struct CalorieRingView: View {
    let progress: Double
    let consumedCalories: Double
    let goalCalories: Double
    let measurementSystem: MeasurementSystem
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 18)
            Circle().trim(from: 0.0, to: min(progress, 1.0))
                .stroke(Color.green.gradient, style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
                .rotationEffect(Angle(degrees: -90))
                .animation(.spring(response: 0.8, dampingFraction: 0.82), value: progress)
            VStack(spacing: 5) {
                Text(measurementSystem.formatEnergy(consumedCalories))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("of \(measurementSystem.formatEnergy(goalCalories))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 152, height: 152)
        .padding(14)
        .background(
            Circle()
                .fill(Color.black.opacity(0.18))
        )
    }
}

private struct MacronutrientCircleView: View {
    let value: Double
    let goal: Double
    let name: String
    let color: Color
    private var progress: Double { goal > 0 ? min(value / goal, 1.0) : 0 }
    private var displayValue: String { String(format: "%.0fg", value) }
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.22), lineWidth: 5)
                Circle().trim(from: 0.0, to: progress).stroke(color.gradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(Angle(degrees: -90))
                Text(displayValue)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            .frame(width: 62, height: 62)
            .animation(.spring(response: 0.75, dampingFraction: 0.85), value: progress)
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct NutritionStatPill: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: LocalizedStringResource(stringLiteral: title)).uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
                .kerning(0.8)

            Text(String(format: "%.0fg", value))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
}

private struct MealTypeButton: View {
    let type: MealType
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: type.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? .green : .white.opacity(0.75))
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.green.opacity(0.16) : Color.white.opacity(0.05))
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? Color.green.opacity(0.35) : Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )

                Text(type.localizedTitle)
                    .font(.caption2.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .green : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

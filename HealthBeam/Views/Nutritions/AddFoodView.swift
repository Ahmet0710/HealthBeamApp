import SwiftUI
import SwiftData
private struct TagFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let rows = generateRows(maxWidth: width, subviews: subviews)
        let height = rows.map { $0.maxHeight }.reduce(0, +) + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = generateRows(maxWidth: bounds.width, subviews: subviews)
        var origin = bounds.origin
        for row in rows {
            for view in row.views {
                let viewSize = view.sizeThatFits(.unspecified)
                view.place(at: origin, proposal: .unspecified)
                origin.x += viewSize.width + spacing
            }
            origin.x = bounds.origin.x
            origin.y += row.maxHeight + spacing
        }
    }

    private func generateRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row(views: [])

        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)

            if currentRow.width + viewSize.width + (currentRow.views.isEmpty ? 0 : spacing) > maxWidth {
                rows.append(currentRow)
                currentRow = Row(views: [])
            }

            currentRow.views.append(view)
        }
        if !currentRow.views.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
    private struct Row {
        var views: [LayoutSubviews.Element]
        var width: CGFloat {
            views.map { $0.sizeThatFits(.unspecified).width }.reduce(0, +) + CGFloat(max(0, views.count - 1)) * 8
        }
        var maxHeight: CGFloat {
            views.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        }
    }
}
struct AddFoodView: View {
    let allMeals: [Meal]
    @EnvironmentObject private var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var foodName: String = ""
    @State private var calories: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var sugar: Double = 0
    @State private var selectedMealType: MealType = .breakfast
    @State private var selectedTags: [String] = []

    private let tagList = ["🥦 Healthy Greens", "🍟 Fast Food", "🍗 High Protein", "🥕 Vegetables", "🍓 Fruit", "🐟 Fish", "🍗 White Meat", "🍬 Sugary", "🌭 Processed Meat", "🥤 Carbonated Drink", "🍕 Pizza", "🍫 Chocolate", "🍰 Dessert", "🍞 Bread", "🧀 Cheese", "🍔 Burger", "🍗 Fried", "🥓 Bacon", "🥛 Dairy", "🍻 Alcohol"]
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                ManualEntryFormView(
                    foodName: $foodName,
                    calories: $calories,
                    protein: $protein,
                    carbs: $carbs,
                    fat: $fat,
                    sugar: $sugar,
                    selectedMealType: $selectedMealType
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Tags")
                        .font(.title3.bold())
                        .padding(.horizontal)

                    TagFlowLayout(spacing: 8) {
                        ForEach(tagList, id: \.self) { tag in
                            TagButton(
                                tag: tag,
                                isSelected: selectedTags.contains(tag),
                                action: {
                                    if selectedTags.contains(tag) {
                                        selectedTags.removeAll { $0 == tag }
                                    } else {
                                        selectedTags.append(tag)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .padding(.horizontal)

        

                Button("Save") {
                    let meal = Meal(
                        id: UUID(),
                        name: foodName,
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        sugar: sugar,
                        time: Date(),
                        mealType: selectedMealType,
                        isManualEntry: true,
                        tags: selectedTags
                    )
                    viewModel.saveMealToHealthKit(meal: meal)
                    modelContext.insert(meal)
                    viewModel.checkAchievementsAfterAdding(meal: meal, allMeals: allMeals + [meal], modelContext: modelContext)
                    dismiss()
                }
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.blue.gradient)
                .cornerRadius(16)
                .padding(.horizontal)
                .disabled(foodName.trimmingCharacters(in: .whitespaces).isEmpty || calories == 0)
            }
            .padding(.vertical)
        }
        .navigationTitle("Add Meal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Dismiss") { dismiss() }
            }
        }
    }
}
private struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .blue : .primary)
                .background(
                    Capsule().fill(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray5))
                )
                .overlay(
                    Capsule().stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

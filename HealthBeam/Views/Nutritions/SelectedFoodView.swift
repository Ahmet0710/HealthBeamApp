import SwiftUI
public struct SelectedFoodView: View {
    @ObservedObject var food: FoodItem
    @State private var isSaved: Bool
    @State private var showUnsaveAlert = false
    let onClearSelection: () -> Void
    var onSaveToggle: ((Bool) -> Void)?
    
    public init(food: FoodItem, onClearSelection: @escaping () -> Void, onSaveToggle: ((Bool) -> Void)? = nil) {
        self.food = food
        self.onClearSelection = onClearSelection
        self.onSaveToggle = onSaveToggle
        self._isSaved = State(initialValue: food.isSaved)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Selected Food")
                    .font(.headline)
                Spacer()
                if onSaveToggle != nil {
                    Button(action: toggleSave) {
                        HStack(spacing: 4) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            Text(isSaved ? "Saved" : "Save")
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(isSaved ? Color.blue : Color(.systemGray5))
                        .foregroundColor(isSaved ? .white : .primary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                Button(action: onClearSelection) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(food.label)
                        .font(.headline)
                    
                    if isSaved {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                if let category = food.categoryLabel {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(isSaved ? .blue.opacity(0.8) : .secondary)
                }
                
                // Nutrition summary
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        NutritionInfoView(value: Int(food.nutrients.energyKcal.rounded()), label: "Cal")
                        NutritionInfoView(value: Int(food.nutrients.protein.rounded()), label: "Protein")
                        NutritionInfoView(value: Int(food.nutrients.carbs.rounded()), label: "Carbs")
                        NutritionInfoView(value: Int(food.nutrients.fat.rounded()), label: "Fat")
                    }
                    
                    if isSaved {
                        Text("Saved to HealthKit")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .padding(.top, 4)
            }
            .padding()
            .background(isSaved ? Color.blue.opacity(0.05) : Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSaved ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .cornerRadius(10)
        }
        .padding(.top, 8)
        .onChange(of: food.isSaved) { oldValue, newValue in
            isSaved = newValue
        }
        .alert(isPresented: $showUnsaveAlert) {
            Alert(
                title: Text("Unsave Food"),
                message: Text("Are you sure you want to remove this food from your saved items?"),
                primaryButton: .destructive(Text("Remove")) {
                    unsaveFood()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func toggleSave() {
        if isSaved {
            showUnsaveAlert = true
        } else {
            let newValue = true
            isSaved = newValue
            food.isSaved = newValue
            onSaveToggle?(newValue)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
        }
    }
    
    private func unsaveFood() {
        let newValue = false
        isSaved = newValue
        food.isSaved = newValue
        onSaveToggle?(newValue)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.warning)
    }
}
struct SelectedFoodView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SelectedFoodView(
                food: FoodItem(
                    foodId: "food_123",
                    label: "Grilled Chicken Breast",
                    nutrients: Nutrients(
                        energyKcal: 165,
                        protein: 31,
                        fat: 3.6,
                        carbs: 0,
                        fiber: nil
                    ),
                    category: "Generic meals",
                    categoryLabel: "Meal",
                    image: nil,
                    isSaved: true
                ),
                onClearSelection: {},
                onSaveToggle: { _ in }
            )
            
            SelectedFoodView(
                food: FoodItem(
                    foodId: "food_124",
                    label: "Brown Rice",
                    nutrients: Nutrients(
                        energyKcal: 215,
                        protein: 5,
                        fat: 1.8,
                        carbs: 45,
                        fiber: 3.5
                    ),
                    category: "Grains",
                    categoryLabel: "Grain",
                    image: nil,
                    isSaved: false
                ),
                onClearSelection: {},
                onSaveToggle: { _ in }
            )
        }
        .padding()
    }
}

import SwiftUI

public struct FoodSearchResultRow: View {
    @ObservedObject public var food: FoodItem
    var onSaveToggle: ((Bool) -> Void)?
    public init(food: FoodItem, onSaveToggle: ((Bool) -> Void)? = nil) {
        self.food = food
        self.onSaveToggle = onSaveToggle
    }
    public var body: some View {
        let _ = print("🔍 FoodSearchResultRow - \(food.label):", 
                     "Cal: \(food.nutrients.energyKcal), ",
                     "P: \(food.nutrients.protein), ",
                     "C: \(food.nutrients.carbs), ",
                     "F: \(food.nutrients.fat)")
        return HStack(alignment: .top, spacing: 8) {
            if food.isSaved {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                    .padding(.top, 2)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(food.label)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(food.isSaved ? .blue : .primary)
                    if food.isSaved {
                        Text("Saved")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }
                if let category = food.categoryLabel {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(food.isSaved ? .blue.opacity(0.8) : .secondary)
                        .lineLimit(1)
                }
                if food.nutrients.energyKcal.isNaN || food.nutrients.energyKcal.isZero {
                    Text("No nutrition data available")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 2)
                } else {
                    HStack(spacing: 12) {
                        NutritionInfoView(value: Int(food.nutrients.energyKcal.rounded()), label: "Cal")
                        NutritionInfoView(value: Int(food.nutrients.protein.rounded()), label: "P")
                        NutritionInfoView(value: Int(food.nutrients.carbs.rounded()), label: "C")
                        NutritionInfoView(value: Int(food.nutrients.fat.rounded()), label: "F")
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            if let _ = onSaveToggle {
                Button(action: toggleSave) {
                    ZStack {
                        Circle()
                            .fill(food.isSaved ? Color.blue.opacity(0.1) : Color.clear)
                            .frame(width: 36, height: 36)
                            .scaleEffect(food.isSaved ? 1.0 : 0.8)
                            .opacity(food.isSaved ? 1.0 : 0.7)
                        Image(systemName: food.isSaved ? "bookmark.fill" : "bookmark")
                            .foregroundColor(food.isSaved ? .blue : .secondary)
                            .font(.system(size: 16))
                            .scaleEffect(food.isSaved ? 1.2 : 1.0)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: food.isSaved)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(food.isSaved ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .animation(.easeInOut, value: food.isSaved)
    }
    
    private func toggleSave() {
        let newValue = !food.isSaved
        food.isSaved = newValue
        onSaveToggle?(newValue)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(newValue ? .success : .warning)
    }
}
struct FoodSearchResultRow_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFoods = [
            FoodItem(
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
            FoodItem(
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
            )
        ]
        List {
            Section(header: Text("Saved Foods")) {
                FoodSearchResultRow(food: sampleFoods[0])
            }
            Section(header: Text("Search Results")) {
                FoodSearchResultRow(food: sampleFoods[1])
            }
        }
        .listStyle(PlainListStyle())
    }
}

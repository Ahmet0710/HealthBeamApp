import SwiftUI
import Combine

struct SearchResultsView: View {
    @ObservedObject var viewModel: FoodSearchViewModel
    let onSelectFood: (FoodItem) -> Void
    let onClearSelection: () -> Void
    
    private var searchResults: [FoodItem] {
        viewModel.searchResults
    }
    
    private var isLoading: Bool {
        viewModel.isLoading
    }
    
    private var errorMessage: String? {
        viewModel.errorMessage
    }
    
    private var searchQuery: String {
        viewModel.searchQuery
    }
    
    public init(viewModel: FoodSearchViewModel,
                onSelectFood: @escaping (FoodItem) -> Void,
                onClearSelection: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onSelectFood = onSelectFood
        self.onClearSelection = onClearSelection
    }
    
    public var body: some View {
        if !searchQuery.isEmpty {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    Text("No results found")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(searchResults) { food in
                        Button(action: {
                            onSelectFood(food)
                        }) {
                            FoodSearchResultRow(
                                food: food,
                                onSaveToggle: { isSaved in
                                    viewModel.updateFoodItemSavedState(foodId: food.foodId, isSaved: isSaved)
                                }
                            )
                            .id(food.foodId + "_" + String(food.isSaved))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .frame(height: 300)
            .listStyle(PlainListStyle())
            .transition(.opacity)
        }
    }
}
struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFood = FoodItem(
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
            isSaved: false
        )
        
        let viewModel = FoodSearchViewModel()
        viewModel.searchQuery = "chicken"
        viewModel.updateSearchResults([sampleFood])
        
        return VStack {
            SearchResultsView(
                viewModel: viewModel,
                onSelectFood: { _ in },
                onClearSelection: {}
            )
        }
    }
}

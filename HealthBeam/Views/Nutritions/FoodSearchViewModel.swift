import Foundation
import Combine
import HealthKit
@MainActor
public final class FoodSearchViewModel: ObservableObject {
    @Published public private(set) var searchResults: [FoodItem] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var selectedFood: FoodItem?
    private let apiService: NutritionAPIService
    private var cancellables = Set<AnyCancellable>()
    @Published public var searchQuery = ""
    public init(apiService: NutritionAPIService? = nil) {
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            self.apiService = NutritionAPIService()
        }
        setupSearchDebounce()
    }
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                Task { [weak self] in
                    await self?.handleSearchQuery(query: query)
                }
            }
            .store(in: &cancellables)
    }
    private func handleSearchQuery(query: String) async {
        if query.isEmpty {
            await MainActor.run {
                self.searchResults = []
            }
            return
        }
        await searchFood(query: query)
    }
    public func searchFood(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                self.searchResults = []
            }
            return
        }
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        do {
            let results = try await apiService.searchFood(query: query)
            await MainActor.run {
                self.searchResults = results
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.searchResults = []
                self.isLoading = false
            }
        }
    }
    public func selectFood(_ food: FoodItem) {
        if let currentSelectedFood = selectedFood, currentSelectedFood.foodId == food.foodId {
            let updatedFood = food.copy()
            updatedFood.isSaved = currentSelectedFood.isSaved
            selectedFood = updatedFood
        } else {
            selectedFood = food.copy()
        }
    }

    public func clearSelection() {
        selectedFood = nil
        searchQuery = ""
        searchResults = []
    }
    
    public func updateSearchResults(_ results: [FoodItem]) {
        self.searchResults = results
    }
    
    public func updateFoodItem(_ food: FoodItem) {
        let updatedFood = food.copy()
        if let index = searchResults.firstIndex(where: { $0.foodId == updatedFood.foodId }) {
            updatedFood.isSaved = searchResults[index].isSaved
            searchResults[index] = updatedFood
        }
        
        if selectedFood?.foodId == updatedFood.foodId {
            updatedFood.isSaved = selectedFood?.isSaved ?? false
            selectedFood = updatedFood
        }
    }
    
    public func updateFoodItemSavedState(foodId: String, isSaved: Bool) {
        if let index = searchResults.firstIndex(where: { $0.foodId == foodId }) {
            searchResults[index].isSaved = isSaved
        }
        
        if selectedFood?.foodId == foodId {
            selectedFood?.isSaved = isSaved
        }
    }
}

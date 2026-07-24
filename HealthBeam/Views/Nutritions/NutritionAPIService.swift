import Foundation
import Combine
public class NutritionAPIService {
    private let appId: String
    private let appKey: String
    private let baseURL = "https://api.edamam.com/api/food-database/v2"
    
    public init(appId: String = APIConfig.edamamAppId, appKey: String = APIConfig.edamamAppKey) {
        self.appId = appId
        self.appKey = appKey
    }
    
    public func searchFood(query: String) async throws -> [FoodItem] {
        guard !query.isEmpty else { return [] }
        
        var components = URLComponents(string: "\(baseURL)/parser")!
        components.queryItems = [
            URLQueryItem(name: "ingr", value: query),
            URLQueryItem(name: "app_id", value: appId),
            URLQueryItem(name: "app_key", value: appKey),
            URLQueryItem(name: "nutrition-type", value: "logging")
        ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(FoodSearchResponse.self, from: data)
        let allFoods = (response.parsed ?? []) + response.hints.map { $0.food }
        var uniqueFoods = [String: FoodItem]()
        for food in allFoods {
            uniqueFoods[food.foodId] = food
        }
        return Array(uniqueFoods.values)
    }
    public func fetchNutritionInfo(foodId: String, measureURI: String, quantity: Double) async throws -> FoodItem {
        let url = URL(string: "\(baseURL)/nutrients")!
        let requestBody: [String: Any] = [
            "ingredients": [
                [
                    "quantity": quantity,
                    "measureURI": measureURI,
                    "foodId": foodId
                ]
            ]
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "app_id", value: appId),
            URLQueryItem(name: "app_key", value: appKey)
        ]
        request.url = components.url
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode([String: [FoodItem]].self, from: data)
        guard let foodItem = response["foods"]?.first else {
            throw NSError(domain: "API Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No food item found"])
        }
        return foodItem
    }
}

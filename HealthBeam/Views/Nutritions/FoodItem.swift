import Foundation
import Combine
public struct FoodSearchResponse: Codable {
    public let hints: [FoodHint]
    public let parsed: [FoodItem]?
    public let text: String
    
    public init(hints: [FoodHint], parsed: [FoodItem]?, text: String) {
        self.hints = hints
        self.parsed = parsed
        self.text = text
    }
    
    public enum CodingKeys: String, CodingKey {
        case hints, parsed, text
    }
}
public struct FoodHint: Codable, Identifiable {
    public let food: FoodItem
    public let measures: [Measure]?
    
    public init(food: FoodItem, measures: [Measure]?) {
        self.food = food
        self.measures = measures
    }
    
    public var id: String { food.foodId }
}
public class FoodItem: Codable, Identifiable, Hashable, ObservableObject {
    public let foodId: String
    public let label: String
    public let nutrients: Nutrients
    public let category: String?
    public let categoryLabel: String?
    public let image: String?
    public let brand: String?
    public let foodContentsLabel: String?
    public let servingSize: Double?
    public let servingUnit: String?
    @Published public var isSaved: Bool {
        didSet {
            objectWillChange.send()
        }
    }
    
    public init(foodId: String, 
                label: String, 
                nutrients: Nutrients, 
                category: String? = nil, 
                categoryLabel: String? = nil, 
                image: String? = nil, 
                brand: String? = nil, 
                foodContentsLabel: String? = nil, 
                servingSize: Double? = nil, 
                servingUnit: String? = nil,
                isSaved: Bool = false) {
        self.foodId = foodId
        self.label = label
        self.nutrients = nutrients
        self.category = category
        self.categoryLabel = categoryLabel
        self.image = image
        self.brand = brand
        self.foodContentsLabel = foodContentsLabel
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.isSaved = isSaved
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let foodIdInt = try? container.decode(Int.self, forKey: .foodId) {
            self.foodId = String(foodIdInt)
        } else {
            self.foodId = try container.decode(String.self, forKey: .foodId)
        }
        self.label = try container.decode(String.self, forKey: .label)
        self.nutrients = try container.decode(Nutrients.self, forKey: .nutrients)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        self.categoryLabel = try container.decodeIfPresent(String.self, forKey: .categoryLabel)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.brand = try container.decodeIfPresent(String.self, forKey: .brand)
        self.foodContentsLabel = try container.decodeIfPresent(String.self, forKey: .foodContentsLabel)
        self.servingSize = try container.decodeIfPresent(Double.self, forKey: .servingSize)
        self.servingUnit = try container.decodeIfPresent(String.self, forKey: .servingUnit)
        self.isSaved = try container.decodeIfPresent(Bool.self, forKey: .isSaved) ?? false
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(foodId, forKey: .foodId)
        try container.encode(label, forKey: .label)
        try container.encode(nutrients, forKey: .nutrients)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(categoryLabel, forKey: .categoryLabel)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(brand, forKey: .brand)
        try container.encodeIfPresent(foodContentsLabel, forKey: .foodContentsLabel)
        try container.encodeIfPresent(servingSize, forKey: .servingSize)
        try container.encodeIfPresent(servingUnit, forKey: .servingUnit)
        try container.encode(isSaved, forKey: .isSaved)
    }
    public var id: String { foodId }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(foodId)
    }
    public static func == (lhs: FoodItem, rhs: FoodItem) -> Bool {
        return lhs.foodId == rhs.foodId && lhs.isSaved == rhs.isSaved
    }
    public func copy() -> FoodItem {
        let copiedNutrients = Nutrients(
            energyKcal: nutrients.energyKcal,
            protein: nutrients.protein,
            fat: nutrients.fat,
            carbs: nutrients.carbs,
            fiber: nutrients.fiber
        )
        let copiedFood = FoodItem(
            foodId: foodId,
            label: label,
            nutrients: copiedNutrients,
            category: category,
            categoryLabel: categoryLabel,
            image: image,
            brand: brand,
            foodContentsLabel: foodContentsLabel,
            servingSize: servingSize,
            servingUnit: servingUnit,
            isSaved: isSaved
        )
        
        return copiedFood
    }
    
    public enum CodingKeys: String, CodingKey {
        case foodId, label, nutrients, category, categoryLabel, image, brand, foodContentsLabel, servingSize, servingUnit, isSaved
    }
    
    public init() {
        self.foodId = ""
        self.label = ""
        self.nutrients = Nutrients(energyKcal: 0, protein: 0, fat: 0, carbs: 0, fiber: nil)
        self.category = nil
        self.categoryLabel = nil
        self.image = nil
        self.brand = nil
        self.foodContentsLabel = nil
        self.servingSize = nil
        self.servingUnit = nil
        self.isSaved = false
    }
}
public struct Nutrients: Codable, Hashable {
    public let energyKcal: Double
    public let protein: Double
    public let fat: Double
    public let carbs: Double
    public let fiber: Double?
    public let sugar: Double? 

    public init(energyKcal: Double,
                protein: Double,
                fat: Double,
                carbs: Double,
                fiber: Double? = nil,
                sugar: Double? = nil) {
        self.energyKcal = energyKcal
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.fiber = fiber
        self.sugar = sugar
    }

    public enum CodingKeys: String, CodingKey {
        case energyKcal = "ENERC_KCAL"
        case protein = "PROCNT"
        case fat = "FAT"
        case carbs = "CHOCDF"
        case fiber = "FIBTG"
        case sugar = "SUGAR"

    }
}
public struct Measure: Codable, Identifiable, Hashable {
    public let uri: String
    public let label: String
    public let weight: Double
    
    public init(uri: String, label: String, weight: Double) {
        self.uri = uri
        self.label = label
        self.weight = weight
    }
    public var id: String { uri }
}

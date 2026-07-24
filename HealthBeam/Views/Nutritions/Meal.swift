import Foundation
import SwiftData
@Model
final class Meal {
    @Attribute(.unique) var id: UUID
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var sugar: Double
    var time: Date
    var mealType: MealType
    var isManualEntry: Bool
    var tags: [String]?

    init(id: UUID = UUID(),
         name: String,
         calories: Double,
         protein: Double,
         carbs: Double,
         fat: Double,
         sugar: Double = 0,
         time: Date,
         mealType: MealType,
         isManualEntry: Bool,
         tags: [String]? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.sugar = sugar
        self.time = time
        self.mealType = mealType
        self.isManualEntry = isManualEntry
        self.tags = tags 
    }
}

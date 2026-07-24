import Foundation
import SwiftData
@Model
final class MealPlan {
    @Attribute(.unique) var id: UUID
    var date: Date
    var mealType: MealType
    var plannedMealName: String
    var isCompleted: Bool
    var notes: String?
    init(id: UUID = UUID(),
         date: Date,
         mealType: MealType,
         plannedMealName: String,
         isCompleted: Bool = false,
         notes: String? = nil) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.plannedMealName = plannedMealName
        self.isCompleted = isCompleted
        self.notes = notes
    }
}

//
//  MockNutrition.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/3/26.
//


// MARK: - MockNutrition.swift
import Foundation

struct MockNutrition {
    /// İnceleme ekibi için günlük örnek beslenme verileri
    static var sampleMeals: [Meal] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            Meal(
                name: "Oatmeal with Blueberries",
                calories: 320,
                protein: 12,
                carbs: 55,
                fat: 6,
                sugar: 10,
                time: calendar.date(bySettingHour: 8, minute: 30, second: 0, of: today)!,
                mealType: .breakfast,
                isManualEntry: true,
                tags: ["Healthy", "Breakfast"]
            ),
            Meal(
                name: "Grilled Chicken Salad",
                calories: 450,
                protein: 45,
                carbs: 12,
                fat: 20,
                sugar: 4,
                time: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: today)!,
                mealType: .lunch,
                isManualEntry: true,
                tags: ["High Protein", "Lunch"]
            ),
            Meal(
                name: "Salmon with Quinoa",
                calories: 680,
                protein: 40,
                carbs: 45,
                fat: 28,
                sugar: 2,
                time: calendar.date(bySettingHour: 19, minute: 30, second: 0, of: today)!,
                mealType: .dinner,
                isManualEntry: true,
                tags: ["Dinner", "Omega 3"]
            )
        ]
    }
    
    /// Su takibi için örnek veriler
    static var sampleWaterLogs: [WaterLogEntry] {
        let calendar = Calendar.current
        let today = Date()
        
        // Rastgele UUID üretip ID çakışmasını önlüyoruz
        return [
            WaterLogEntry(id: UUID(), amountLiters: 0.5, date: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!),
            WaterLogEntry(id: UUID(), amountLiters: 0.75, date: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!),
            WaterLogEntry(id: UUID(), amountLiters: 0.5, date: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!)
        ]
    }
}

import Foundation
import SwiftUI

struct Habit: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var icon: String
    var color: String
    var isCompleted: Bool
    var streak: Int
    var time: DateComponents
    var completionDates: Set<Date>
    var category: String

    var colorValue: Color {
        Color(hex: color) ?? .black
    }

    var localizedCategory: String {
        switch category {
        case "Morning": return String(localized: "Morning")
        case "Afternoon": return String(localized: "Afternoon")
        case "Evening": return String(localized: "Evening")
        case "All": return String(localized: "All")
        default: return category
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, icon, color, isCompleted, streak, time, completionDates, category
    }

    init(id: UUID = UUID(), name: String, icon: String, color: String, isCompleted: Bool, streak: Int, time: DateComponents, completionDates: Set<Date>, category: String = "") {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.isCompleted = isCompleted
        self.streak = streak
        self.time = time
        self.completionDates = completionDates
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        color = try container.decode(String.self, forKey: .color)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        streak = try container.decode(Int.self, forKey: .streak)
        time = try container.decode(DateComponents.self, forKey: .time)
        completionDates = try container.decode(Set<Date>.self, forKey: .completionDates)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(color, forKey: .color)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(streak, forKey: .streak)
        try container.encode(time, forKey: .time)
        try container.encode(completionDates, forKey: .completionDates)
        try container.encode(category, forKey: .category)
    }
}

struct Badge: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let milestone: Int 
    var unlocked: Bool = false

    var localizedName: String { String(localized: String.LocalizationValue(name)) }
    var localizedDescription: String { String(localized: String.LocalizationValue(description)) }
}

private enum HabitLocalizationCatalog {
    // Keeps dynamic category and badge strings in a localizable context for extraction.
    static let strings: [LocalizedStringResource] = [
        "All", "Morning", "Afternoon", "Evening",
        "5 Day Streak", "Complete a habit 5 days in a row",
        "10 Day Streak", "Complete a habit 10 days in a row",
        "Habit Master", "Complete all habits for a week"
    ]
}

let allBadges = [
    Badge(id: UUID(), name: "5 Day Streak", description: "Complete a habit 5 days in a row", icon: "flame.fill", milestone: 5),
    Badge(id: UUID(), name: "10 Day Streak", description: "Complete a habit 10 days in a row", icon: "flame.fill", milestone: 10),
    Badge(id: UUID(), name: "Habit Master", description: "Complete all habits for a week", icon: "star.fill", milestone: 7)
]

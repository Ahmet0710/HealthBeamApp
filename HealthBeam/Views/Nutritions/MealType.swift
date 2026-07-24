import Foundation
public enum MealType: String, Codable, CaseIterable, Hashable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"

    public var id: String { rawValue }
    public var localizedTitle: String {
        String(localized: LocalizedStringResource(stringLiteral: rawValue))
    }
    public var systemImage: String {
        switch self {
        case .breakfast:
            return "sunrise.fill"
        case .lunch:
            return "fork.knife"
        case .dinner:
            return "moon.stars.fill"
        }
    }

    static let localizationSeed: [LocalizedStringResource] = [
        "Breakfast",
        "Lunch",
        "Dinner"
    ]
}

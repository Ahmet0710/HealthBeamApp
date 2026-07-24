import SwiftUI
import Foundation
enum NotificationTimeRange: String, CaseIterable, Identifiable {
    case last6Months
    case allTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .last6Months: return String(localized: "Last 6 Months")
        case .allTime: return String(localized: "All Time")
        }
    }

    var startDate: Date {
        let calendar = Calendar.current
        switch self {
        case .last6Months:
            return calendar.date(byAdding: .month, value: -6, to: Date()) ?? .distantPast
        case .allTime:
            return .distantPast
        }
    }
}

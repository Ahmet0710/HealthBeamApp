import Foundation
import SwiftUI
struct HeartNotificationSummary: Identifiable {
    let id = UUID()
    let type: HeartNotificationType
    let count: Int
}

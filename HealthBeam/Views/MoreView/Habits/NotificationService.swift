import Foundation
@preconcurrency import UserNotifications

/// NotificationService handles scheduling and canceling local notifications for habits,
/// without directly depending on the Habit type.
/// It attempts to extract required properties via reflection from the passed habit object.
public class NotificationService {
    
    /// Requests notification authorization if not already granted.
    /// Calls completion(true) if authorized, false otherwise, always on main thread.
    public func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        nonisolated(unsafe) let completionCopy = completion
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                Task { @MainActor in
                    completionCopy(true)
                }
            case .denied, .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    Task { @MainActor in
                        completionCopy(granted)
                    }
                }
            @unknown default:
                Task { @MainActor in
                    completionCopy(false)
                }
            }
        }
    }
    
    /// Schedules a local notification for a habit, extracting necessary info by reflection.
    /// If required info is missing or notifications are disabled, no notification is scheduled.
    ///
    /// - Parameter habit: The habit object to schedule notification for.
    ///                    Expected properties (by convention):
    ///                    - id: UUID
    ///                    - notificationsEnabled: Bool (optional)
    ///                    - title or name: String
    ///                    - reminderTime: Date?, DateComponents?, or similar (optional)
    public func scheduleNotification(for habit: Any) {
        // Extract id (UUID)
        guard let id: UUID = findFirstValue(in: habit, propertyNames: ["id", "uuid"]) else { return }
        
        // Extract notificationsEnabled flag (optional)
        let notificationsEnabled: Bool? = findFirstValue(in: habit, propertyNames: ["notificationsEnabled", "notificationsOn", "isNotificationEnabled"])
        if let enabled = notificationsEnabled, enabled == false { return }
        
        // Extract title or name
        let title: String? = findFirstValue(in: habit, propertyNames: ["title", "name", "habitTitle", "habitName"])
        let notificationTitle = title ?? "Habit Reminder"
        
        // Extract reminder time (Date or DateComponents)
        let reminderDate: Date? = findFirstValue(in: habit, propertyNames: ["reminderTime", "reminderDate", "time", "reminder"])
        let reminderComponents: DateComponents? = findFirstValue(in: habit, propertyNames: ["reminderComponents", "reminderDateComponents", "timeComponents"])
        
        // Determine trigger
        let trigger: UNNotificationTrigger?
        if let date = reminderDate {
            let calendar = Calendar.current
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        } else if let comps = reminderComponents {
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        } else {
            // No valid trigger info found
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = notificationTitle
        content.body = "Don't forget your habit today."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                // Debug print - remove or comment out in production
                #if DEBUG
                print("Failed to schedule notification: \(error)")
                #endif
            }
        }
    }
    
    /// Cancels a scheduled notification for the given habit id.
    /// - Parameter id: The UUID identifier of the habit notification to cancel.
    public func cancelNotification(for id: UUID) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
    
    /// Helper function to find the first value of specified property names in the given object via Mirror,
    /// casted to the expected type.
    /// - Parameters:
    ///   - object: The object to reflect on.
    ///   - propertyNames: Possible property names to try.
    /// - Returns: The first value found matching the expected type, or nil if not found.
    private func findFirstValue<T>(in object: Any, propertyNames: [String]) -> T? {
        let mirror = Mirror(reflecting: object)
        
        // Search current level
        for child in mirror.children {
            if let label = child.label, propertyNames.contains(label), let value = child.value as? T {
                return value
            }
        }
        // Search superclass if any
        if let superclassMirror = mirror.superclassMirror {
            for child in superclassMirror.children {
                if let label = child.label, propertyNames.contains(label), let value = child.value as? T {
                    return value
                }
            }
        }
        return nil
    }
}

#if DEBUG
/// Placeholder struct documenting expected properties of a Habit for NotificationService,
/// used only in debug builds for documentation purposes.
public struct HabitPlaceholder {
    public let id: UUID
    public let title: String
    public let notificationsEnabled: Bool
    public let reminderTime: Date?
    public let reminderComponents: DateComponents?
}
#endif

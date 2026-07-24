import UserNotifications

class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    // MARK: - Schedule Notification
    func scheduleNotification(for medicationId: UUID, name: String, time: Date) {

        let content = UNMutableNotificationContent()
        content.title = "Medication Time 💊"
        content.body = "It's time to take your \(name)."
        content.sound = .default

        // Extract hour & minute from the given time
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)

        // Repeat every day at the same time
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: medicationId.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification could not be scheduled: \(error.localizedDescription)")
            } else {
                print("✅ Notification scheduled: \(name) at \(time.formatted(date: .omitted, time: .shortened))")
            }
        }
    }

    // MARK: - Cancel Notification
    func cancelNotification(id: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }

    // MARK: - Request Authorization
    func requestAuthorization() {

        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in

            if granted {
                print("✅ Notification permission granted.")
            } else if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            } else {
                print("⚠️ Notification permission denied.")
            }
        }
    }
}

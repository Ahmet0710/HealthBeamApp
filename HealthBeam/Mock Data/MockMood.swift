import Foundation

struct MockMood {
    static var sampleEntries: [MoodEntry] {
        let calendar = Calendar.current
        let now = Date()

        return [
            MoodEntry(
                date: calendar.date(bySettingHour: 8, minute: 10, second: 0, of: now) ?? now,
                moodKind: .happy,
                title: "Good",
                tags: ["Focused", "Optimistic"],
                noteText: "Strong start after sleep and a short walk."
            ),
            MoodEntry(
                date: calendar.date(bySettingHour: 14, minute: 5, second: 0, of: now) ?? now,
                moodKind: .relaxed,
                title: "Pleasant",
                tags: ["Calm", "Balanced"],
                noteText: "Lunch break helped reset the day."
            ),
            MoodEntry(
                date: calendar.date(bySettingHour: 21, minute: 15, second: 0, of: calendar.date(byAdding: .day, value: -1, to: now) ?? now) ?? now,
                moodKind: .grateful,
                title: "Pleasant",
                tags: ["Grateful", "Connected"],
                noteText: "Family time lifted my mood."
            ),
            MoodEntry(
                date: calendar.date(bySettingHour: 23, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -2, to: now) ?? now) ?? now,
                moodKind: .thoughtful,
                title: "Neutral",
                tags: ["Thoughtful", "Measured"],
                noteText: "Processing a lot mentally before bed."
            ),
            MoodEntry(
                date: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: -3, to: now) ?? now) ?? now,
                moodKind: .joyful,
                title: "Very Pleasant",
                tags: ["Excited", "Inspired"],
                noteText: "Weekend plans boosted my energy."
            )
        ]
    }
}

import Foundation
import SwiftData

@MainActor
private func localizedMoodText(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: key, table: nil)
}

enum MoodKind: String, CaseIterable, Codable, Identifiable {
    case joyful
    case happy
    case excited
    case relaxed
    case grateful
    case thoughtful
    case neutral
    case tired
    case sad
    case angry

    var id: String { rawValue }

    var score: Double {
        switch self {
        case .joyful: 5.0
        case .happy: 4.5
        case .excited: 4.3
        case .relaxed: 4.0
        case .grateful: 4.2
        case .thoughtful: 3.2
        case .neutral: 3.0
        case .tired: 2.3
        case .sad: 1.6
        case .angry: 1.0
        }
    }
}

@Model
final class MoodEntry: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var moodRawValue: String
    var title: String
    var tags: [String]
    var noteText: String

    init(
        id: UUID = UUID(),
        date: Date,
        moodKind: MoodKind,
        title: String,
        tags: [String] = [],
        noteText: String = ""
    ) {
        self.id = id
        self.date = date
        self.moodRawValue = moodKind.rawValue
        self.title = title
        self.tags = tags
        self.noteText = noteText
    }

    var moodKind: MoodKind {
        get { MoodKind(rawValue: moodRawValue) ?? .neutral }
        set { moodRawValue = newValue.rawValue }
    }

    @MainActor var localizedTitle: String {
        localizedMoodText(title)
    }

    @MainActor var tagsDisplayText: String {
        if tags.isEmpty {
            return localizedTitle
        }
        return tags.map(localizedMoodText).joined(separator: ", ")
    }

    @MainActor var localizedNoteText: String {
        if noteText.isEmpty {
            return localizedMoodText("No note was added for this check-in.")
        }

        let localized = localizedMoodText(noteText)
        return localized == noteText ? noteText : localized
    }
}

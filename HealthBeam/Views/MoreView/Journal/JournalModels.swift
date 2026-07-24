import Foundation
import SwiftData
import MapKit
import UIKit
import Combine

enum JournalAchievementTag: String, CaseIterable, Codable, Identifiable {
    case gratitude
    case goals
    case brainstorm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gratitude: return "Gratitude"
        case .goals: return "Goals"
        case .brainstorm: return "Brainstorm"
        }
    }
}

@Model
final class JournalEntry: Identifiable, Hashable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var title: String
    var mood: String?
    var achievementTagValues: [String]?
    var isBookmarked: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \ContentBlock.journalEntry)
    var contentBlocks: [ContentBlock]? = []
    init(id: UUID = UUID(), date: Date, title: String, mood: String? = nil, achievementTagValues: [String] = [], isBookmarked: Bool = false) {
        self.id = id
        self.date = date
        self.title = title
        self.mood = mood
        self.achievementTagValues = achievementTagValues
        self.isBookmarked = isBookmarked
    }

    var sortedContentBlocks: [ContentBlock] {
        contentBlocks?.sorted { $0.creationDate < $1.creationDate } ?? []
    }

    var achievementTags: Set<JournalAchievementTag> {
        Set((achievementTagValues ?? []).compactMap(JournalAchievementTag.init(rawValue:)))
    }

    static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
@Model
final class ContentBlock {
    enum ContentType: String, Codable { case text, location, audio, image }
    var id: UUID
    var creationDate: Date
    var type: ContentType
    var textValue: String?
    var locationName: String?
    var latitude: Double?
    var longitude: Double?
    var audioURLString: String?
    var audioDuration: TimeInterval?
    @Attribute(.externalStorage) var imageData: Data?
    var journalEntry: JournalEntry?

    init(text: String) { self.id = UUID(); self.creationDate = Date(); self.type = .text; self.textValue = text }
    init(name: String, latitude: Double, longitude: Double) { self.id = UUID(); self.creationDate = Date(); self.type = .location; self.locationName = name; self.latitude = latitude; self.longitude = longitude }
    init(url: URL, duration: TimeInterval) { self.id = UUID(); self.creationDate = Date(); self.type = .audio; self.audioURLString = url.absoluteString; self.audioDuration = duration }
    init(image: UIImage) { self.id = UUID(); self.creationDate = Date(); self.type = .image; self.imageData = image.jpegData(compressionQuality: 0.8) }

    var audioURL: URL? { URL(string: audioURLString ?? "") }
    var image: UIImage? { imageData.flatMap(UIImage.init) }
}

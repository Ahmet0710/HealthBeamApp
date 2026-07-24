import Foundation

struct ChatMessage: Identifiable, Equatable, Codable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let timestamp: Date

    init(id: UUID = UUID(), text: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}

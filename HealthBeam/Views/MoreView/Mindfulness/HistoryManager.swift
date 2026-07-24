import Foundation

class HistoryManager {
    static let shared = HistoryManager()
    private let historyKey = "meditationHistory"

    func addSession(meditationID: UUID) {
        var completedSessions = loadSessions()
        let newSession = CompletedSession(meditationID: meditationID, completionDate: Date())
        completedSessions.append(newSession)
        saveSessions(completedSessions)
    }

    func loadSessions() -> [CompletedSession] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        do {
            let sessions = try JSONDecoder().decode([CompletedSession].self, from: data)
            return sessions.sorted { $0.completionDate > $1.completionDate }
        } catch {
            print("Geçmiş verisi okunamadı: \(error)")
            return []
        }
    }

    private func saveSessions(_ sessions: [CompletedSession]) {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Geçmiş verisi kaydedilemedi: \(error)")
        }
    }
}

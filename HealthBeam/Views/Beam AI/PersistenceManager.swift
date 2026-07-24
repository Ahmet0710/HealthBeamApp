import Foundation
import Swift
import SwiftUI
import Combine

class PersistenceManager {
    
    func save(messages: [ChatMessage], for userID: String) {
        do {
            let fileURL = getFileURL(for: userID)
            let data = try JSONEncoder().encode(messages)
            try data.write(to: fileURL, options: .atomic)
        } catch {
        }
    }
    func load(for userID: String) -> [ChatMessage]? {
        let fileURL = getFileURL(for: userID)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let messages = try JSONDecoder().decode([ChatMessage].self, from: data)
            return messages
        } catch {
            return nil
        }
    }
    
    func delete(for userID: String) {
        let fileURL = getFileURL(for: userID)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
            }
        }
    }
    private func getFileURL(for userID: String) -> URL {
        let fileName = "\(userID)_chatHistory.json"
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
}

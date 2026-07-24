import Foundation

class FavoritesManager {
    static let shared = FavoritesManager()
    private let favoritesKey = "favoriteMeditationIDs"
    func loadFavorites() -> [String] {
        return UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
    }
    private func saveFavorites(_ ids: [String]) {
        UserDefaults.standard.set(ids, forKey: favoritesKey)
    }
    func isFavorite(meditationID: UUID) -> Bool {
        let favorites = loadFavorites()
        return favorites.contains(meditationID.uuidString)
    }
    func toggleFavorite(meditationID: UUID) {
        var favorites = loadFavorites()
        let idString = meditationID.uuidString
        if isFavorite(meditationID: meditationID) {
            favorites.removeAll { $0 == idString }
        } else {
            favorites.append(idString)
        }
        saveFavorites(favorites)
    }
}

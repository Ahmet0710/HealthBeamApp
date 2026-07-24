import SwiftUI
import Combine

class AppReviewManager: ObservableObject {
    static let shared = AppReviewManager()
    
    @Published var isDemoMode: Bool = false
    
    // Apple'a vereceğin test e-postası.
    // Küçük harf olmasına dikkat et.
    private let reviewUserEmail = "test_account@healthbeamapp.com"

    @MainActor
    func checkReviewStatus(email: String?) {
        guard let email = email?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) else {
            self.isDemoMode = false
            return
        }
        
        if email == reviewUserEmail {
            self.isDemoMode = true
            print(" [HealthBeam] Demo Modu Aktif: İnceleme ekibi giriş yaptı.")
        } else {
            self.isDemoMode = false
        }
    }
}

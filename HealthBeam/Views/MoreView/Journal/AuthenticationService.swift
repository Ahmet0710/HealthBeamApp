import Foundation
import LocalAuthentication
import Combine
import FirebaseAuth
@MainActor
class AuthenticationService: ObservableObject {
    @Published var isUnlocked = false
    @Published var canAuthenticate = false

    private var context = LAContext()
    private var isAuthenticating = false

    init() {
        var error: NSError?
        canAuthenticate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
        
    func signUp(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }
        
    func signOut() async {
        do {
            try Auth.auth().signOut()
            isUnlocked = false
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
        
    func authenticate() async {
        guard canAuthenticate, !isAuthenticating else { return }

        isAuthenticating = true
        defer { self.isAuthenticating = false }
        
        let localContext = LAContext()
        localContext.localizedFallbackTitle = ""
        
        do {
            let success = try await localContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: NSLocalizedString("Please unlock using biometrics.", comment:"")
            )
            self.isUnlocked = success
        } catch {
            self.isUnlocked = false
        }
    }

    func lock() {
        self.isUnlocked = false
    }
    
    func requestUserVerification(reason: String) async -> Bool {
        guard !isAuthenticating else { return false }

        isAuthenticating = true
        defer { self.isAuthenticating = false }

        let localContext = LAContext()
        localContext.localizedFallbackTitle = ""

        do {
            return try await localContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}

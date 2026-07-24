import Foundation
import FirebaseAuth

class UserManager: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var hasCheckedInitialStatus: Bool = false
    var currentUser: User? { return Auth.auth().currentUser }
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        addAuthStateListener()
    }
    
    func addAuthStateListener() {
        if authStateHandle != nil {
            Auth.auth().removeStateDidChangeListener(authStateHandle!)
        }
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isSignedIn = (user != nil)
                self.hasCheckedInitialStatus = true
            }
        }
    }
}


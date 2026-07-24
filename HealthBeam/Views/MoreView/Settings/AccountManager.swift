import Foundation
import FirebaseAuth
import FirebaseFirestore
import CryptoKit
import Combine
import SwiftUI
@MainActor
class AccountManager: ObservableObject {
    @Published var user: User?
    private var db = Firestore.firestore()
    nonisolated(unsafe) private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signUp(name: String, email: String, password: String) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        AppReviewManager.shared.checkReviewStatus(email: email)
        self.user = authResult.user
        let user = authResult.user
        try await updateDisplayName(name, for: user)
        let encryptedName = try encryptString(name)
        let encryptedEmail = try encryptString(email)
        let encryptedPassword = try encryptString(password)
        let userData: [String: Any] = ["fullName": encryptedName,"email": encryptedEmail,"encryptedPassword": encryptedPassword]
        try await db.collection("users").document(user.uid).setData(userData, merge: true)
        self.user = user
    }

    func signIn(email: String, password: String) async throws {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        AppReviewManager.shared.checkReviewStatus(email: email)
        self.user = authResult.user
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            AppReviewManager.shared.isDemoMode = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    private func getOrCreateSymmetricKey() throws -> SymmetricKey {
        // ...
        let tag = "com.healthbeam.e2e.key".data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag,
            kSecReturnData as String: true,
            kSecAttrService as String: "encryption-key",
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let keyData = item as? Data {
            return SymmetricKey(data: keyData)
        } else {
            let key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: tag,
                kSecValueData as String: keyData,
                kSecAttrService as String: "encryption-key",
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw NSError(domain: "AccountManager", code: Int(addStatus), userInfo: [NSLocalizedDescriptionKey: "Encryption key could not be stored in Keychain."])
            }
            return key
        }
    }

    private func encryptString(_ plaintext: String) throws -> String {
        let key = try getOrCreateSymmetricKey()
        let data = Data(plaintext.utf8)
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw NSError(domain: "AccountManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Encryption failed: Could not get combined data."])
        }
        return combined.base64EncodedString()
    }

    private func updateDisplayName(_ name: String, for user: User) async throws {
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            changeRequest.commitChanges { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

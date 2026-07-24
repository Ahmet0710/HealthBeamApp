import SwiftUI
import PhotosUI
import HealthKit
import UIKit
import Combine
import UserNotifications
import AuthenticationServices
import FirebaseCore
@preconcurrency import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CryptoKit
import RevenueCat



struct SwiftUISignInWithAppleButton: View {
    @EnvironmentObject var manager: AppleSignInManager
    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { req in
                let nonce = manager.randomNonceString()
                manager.currentNonce = nonce
                req.nonce = manager.sha256(nonce)
                req.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                manager.handle(result: result)
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 44)
        .padding(.horizontal, 24)
    }
}

@MainActor
class AppleSignInManager: NSObject, ObservableObject {
    @Published var userFullName: String? = nil
    @Published var userEmail: String? = nil
    @Published var isSignedIn: Bool = false
    @Published var errorMessage: String? = nil
    @Published var userProfileImageURL: String? = nil
    @Published var userProfileImage: UIImage? = nil
    
    var onSignInSuccess: (() -> Void)? = nil
    var currentNonce: String?
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    static let encryptionKeyTag = "com.healthbeam.e2e.key"
    
    // MARK: - INIT (Otomatik Oturum Kontrolü)
    override init() {
        super.init()
        DispatchQueue.main.async {
            self.checkCurrentAuthStatus()
        }
    }
    
    // Uygulama açıldığında Firebase'de oturum var mı diye bakar
    // Uygulama açıldığında çalışır
        func checkCurrentAuthStatus() {
            // UserDefaults, uygulama silinince SİLİNİR.
            // Keychain ise uygulama silinse de KALIR.
            // Bu farkı kullanarak "Silinip tekrar yüklenme" durumunu yakalıyoruz.
            
            let hasRunBefore = UserDefaults.standard.bool(forKey: "hasRunBefore")
            
            if !hasRunBefore {
                // DURUM: Uygulama ya ilk kez yüklendi ya da silinip tekrar yüklendi.
                // Bu durumda Keychain'den gelen eski oturumu GÜVENLİK GEREĞİ temizliyoruz.
                print("🚀 Taze Kurulum Tespit Edildi: Varsa eski oturum temizleniyor...")
                
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("Sign out error: \(error)")
                }
                
                // Bayrağı dikiyoruz: Artık bu uygulama "çalışmış" sayılır.
                UserDefaults.standard.set(true, forKey: "hasRunBefore")
                
                self.isSignedIn = false
                self.userFullName = nil
                self.userEmail = nil
                self.userProfileImage = nil
                
            } else {
                // DURUM: Uygulama silinmemiş, sadece kapatılıp açılmış (Kill/Restart).
                // Oturumu koruyoruz.
                if let user = Auth.auth().currentUser {
                    print("✅ Mevcut oturum ile devam ediliyor (UID: \(user.uid))")
                    self.isSignedIn = true
                    self.fetchUserNameFromFirestore()
                } else {
                    print("ℹ️ Giriş yapmış kullanıcı yok.")
                    self.isSignedIn = false
                }
            }
        }
    private func getOrCreateSymmetricKey() -> SymmetricKey {
        let tag = AppleSignInManager.encryptionKeyTag.data(using: .utf8)!
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
                print("[AppleSignInManager][Error] Encryption key could not be stored in Keychain: \(addStatus)")
            }
            return key
        }
    }
    
    private func encryptString(_ plaintext: String) -> String {
        let key = getOrCreateSymmetricKey()
        let data = Data(plaintext.utf8)
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            let combined = sealedBox.combined!
            return combined.base64EncodedString()
        } catch {
            print("[AppleSignInManager][Error] Encryption failed: \(error.localizedDescription)")
            return ""
        }
    }
    
    private func decryptString(_ ciphertext: String) -> String {
        let key = getOrCreateSymmetricKey()
        guard let data = Data(base64Encoded: ciphertext) else {
            print("[AppleSignInManager][Error] Decryption failed: Base64 decoding failed")
            return ""
        }
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8) ?? ""
        } catch {
            print("[AppleSignInManager][Error] Decryption failed: \(error.localizedDescription)")
            return ""
        }
    }
    
    func savePassword(_ password: String) {
        guard let user = Auth.auth().currentUser else { return }
        let encryptedPassword = encryptString(password)
        db.collection("users").document(user.uid).setData([
            "password": encryptedPassword
        ], merge: true)
    }
    
    func verifyPassword(_ rawPassword: String) async -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        do {
            let doc = try await db.collection("users").document(user.uid).getDocument()
            guard let pw = doc.data()?["password"] as? String, !pw.isEmpty else { return false }
            let decrypted = decryptString(pw)
            return decrypted == rawPassword
        } catch {
            return false
        }
    }
    
    func changePassword(old: String, new: String) async -> Bool {
        let isOK = await verifyPassword(old)
        guard isOK else { return false }
        savePassword(new)
        return true
    }
    
    func hasPassword() async -> Bool {
        guard let user = Auth.auth().currentUser else { return false }
        do {
            let doc = try await db.collection("users").document(user.uid).getDocument()
            return (doc.data()?["password"] as? String).map { !$0.isEmpty } ?? false
        } catch {
            return false
        }
    }

    func saveEncryptedRecoveryKeys(_ codes: [String]) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AppleSignInManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No signed-in user."])
        }
        let jsonData = try JSONEncoder().encode(codes)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "[]"
        let encrypted = encryptString(jsonString)
        try await db.collection("users").document(user.uid).setData([
            "recoveryKeys": encrypted
        ], merge: true)
    }

    func verifyRecoveryKeys(_ userInputKeys: [String]) async throws -> Bool {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AppleSignInManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No signed-in user."])
        }
        let doc = try await db.collection("users").document(user.uid).getDocument()
        guard let data = doc.data(),
              let encrypted = data["recoveryKeys"] as? String,
              !encrypted.isEmpty else {
            return false
        }
        let decryptedJSON = decryptString(encrypted)
        guard let jsonData = decryptedJSON.data(using: .utf8) else {
            return false
        }
        let storedCodes = try JSONDecoder().decode([String].self, from: jsonData)
        let normalize: (String) -> String = { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
        let storedSet = Set(storedCodes.map(normalize))
        let inputSet = Set(userInputKeys.map(normalize))
        return storedSet == inputSet && !storedSet.isEmpty
    }
    
    @MainActor
    func handle(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken else {
                self.errorMessage = "Apple'dan kimlik token'ı alınamadı."
                return
            }
            guard let tokenString = String(data: appleIDToken, encoding: .utf8) else {
                self.errorMessage = "Token string'e dönüştürülemedi."
                return
            }
            guard let nonce = currentNonce else {
                self.errorMessage = "Nonce missing. Lütfen tekrar deneyin."
                return
            }
            currentNonce = nil
            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: tokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            Task {
                do {
                    let authResult = try await Auth.auth().signIn(with: firebaseCredential)
                    let user = authResult.user
                    Purchases.shared.logIn(user.uid) { (customerInfo, created, error) in
                        if error != nil {
                        } else {
                        }
                    }
                    let fullName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
                    let actualEmail: String = appleIDCredential.email ?? user.email ?? ""
                    
                    // Demo Kontrolünü hemen yap
                    AppReviewManager.shared.checkReviewStatus(email: actualEmail)
                    
                    let document = try? await self.db.collection("users").document(user.uid).getDocument()
                    if let doc = document, doc.exists, let data = doc.data() {
                        self.userFullName = (data["fullName"] as? String).map(decryptString) ?? fullName
                        self.userEmail = (data["email"] as? String).map(decryptString) ?? actualEmail
                        self.userProfileImageURL = data["profileImageURL"] as? String
                    } else {
                        let encryptedName = self.encryptString(fullName)
                        let encryptedEmail = self.encryptString(actualEmail)
                        try await self.db.collection("users").document(user.uid).setData([
                            "fullName": encryptedName, "email": encryptedEmail
                        ], merge: true)
                        self.userFullName = fullName
                        self.userEmail = actualEmail
                        self.userProfileImageURL = nil
                    }
                    self.isSignedIn = true
                    self.userProfileImage = self.loadProfileImageLocally(for: user.uid)
                    self.errorMessage = nil
                    self.onSignInSuccess?()
                } catch {
                    self.errorMessage = "Firebase ile giriş başarısız: \(error.localizedDescription)"
                }
            }
        case .failure(let err):
            self.errorMessage = "failed to sign in with Apple: \(err.localizedDescription)"
        }
    }
    
    func updateUserProfile(name: String, email: String, image: UIImage?) {
        self.userFullName = name
        self.userEmail = email
        guard let user = Auth.auth().currentUser else { return }
        let encryptedName = encryptString(name)
        let encryptedEmail = encryptString(email)
        db.collection("users").document(user.uid).setData([
            "fullName": encryptedName,
            "email": encryptedEmail
        ], merge: true)
        if let image = image {
            saveProfileImageLocally(image, uid: user.uid)
            if let localImage = loadProfileImageLocally(for: user.uid) {
                DispatchQueue.main.async {
                    self.userProfileImage = localImage
                }
            }
        }
    }
    
    func saveProfileImageLocally(_ image: UIImage, uid: String) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        let fileURL = getDocumentsDirectory().appendingPathComponent("profile_photos/\(uid).jpg")
        do {
            let folderURL = fileURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: folderURL.path) {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            }
            try data.write(to: fileURL)
        } catch {
        }
    }
    
    func loadProfileImageLocally(for uid: String) -> UIImage? {
        let fileURL = getDocumentsDirectory().appendingPathComponent("profile_photos/\(uid).jpg")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                return image
            }
        }
        return nil
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            Purchases.shared.logOut { (customerInfo, error) in
                if error != nil {
                } else {
                }
            }
            self.userProfileImage = nil
            self.userProfileImageURL = nil
            self.isSignedIn = false
            self.userFullName = nil
            self.userEmail = nil
            
            // DEMO MODUNU KAPAT
            AppReviewManager.shared.isDemoMode = false
            
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "userFullName")
            defaults.removeObject(forKey: "userEmail")
            defaults.removeObject(forKey: "userProfileImageURL")
        } catch {
            self.errorMessage = "Cannot logged Out: \(error.localizedDescription)"
        }
    }
    
    func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    // BU FONKSİYONU GÜNCELLEDİK: Mail gelir gelmez Demo Kontrolü yapıyor.
    func fetchUserNameFromFirestore() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        db.collection("users").document(user.uid).getDocument { [weak self] document, _ in
            guard let self else { return }
            Task { @MainActor in
                if let document = document, let data = document.data() {
                    let name = (data["fullName"] as? String).flatMap { self.decryptString($0) } ?? ""
                    let email = (data["email"] as? String).flatMap { self.decryptString($0) } ?? ""
                    
                    self.userFullName = name
                    self.userEmail = email
                    
                    // 🔥 KRİTİK NOKTA: Mail adresini aldığımız anda Demo kontrolü yap!
                    AppReviewManager.shared.checkReviewStatus(email: email)
                    
                    self.userProfileImageURL = data["profileImageURL"] as? String
                    self.isSignedIn = true
                    self.userProfileImage = self.loadProfileImageLocally(for: user.uid)
                }
            }
        }
    }
    
    func profilePhotoRef(for uid: String) -> StorageReference {
        return storage.reference().child("profile_photos/\(uid).jpg")
    }
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "No user", code: 0)
        }
        try await db.collection("users").document(user.uid).delete()
        let fileURL = self.getDocumentsDirectory().appendingPathComponent("profile_photos/\(user.uid).jpg")
        try? FileManager.default.removeItem(at: fileURL)
        try await user.delete()
        self.userProfileImage = nil
        self.userProfileImageURL = nil
        self.isSignedIn = false
        self.userFullName = nil
        self.userEmail = nil
        AppReviewManager.shared.isDemoMode = false
    }
    
    func requestAccountDeletion() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AppleSignInManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No signed-in user."])
        }
        let userId = user.uid
        let encryptedUserId = encryptString(userId)
        let timestamp = FieldValue.serverTimestamp()
        let status = "pending"
        let deletionRequestData: [String: Any] = [
            "encryptedUserId": encryptedUserId,
            "timestamp": timestamp,
            "status": status
        ]
        try await db.collection("deletionRequests").document(userId).setData(deletionRequestData)
        self.signOut()
    }
}

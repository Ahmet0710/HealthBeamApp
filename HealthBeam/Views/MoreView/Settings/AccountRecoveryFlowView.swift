import SwiftUI
import CryptoKit
import AuthenticationServices
import Combine
import CommonCrypto
enum PBKDF2Helper {
    enum Error: Swift.Error {
        case derivationFailed(OSStatus)
        case invalidParameters
    }

    static func deriveKey(password: String, salt: Data, iterations: UInt32 = 100_000, keyLength: Int = 32) throws -> Data {
        guard let passwordData = password.data(using: .utf8) else { throw Error.invalidParameters }
        var derivedKey = Data(count: keyLength)
        let status = derivedKey.withUnsafeMutableBytes { derivedBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    (passwordData as NSData).bytes.bindMemory(to: Int8.self, capacity: passwordData.count),
                    passwordData.count,
                    saltBytes.bindMemory(to: UInt8.self).baseAddress,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    iterations,
                    derivedBytes.bindMemory(to: UInt8.self).baseAddress,
                    keyLength
                )
            }
        }
        guard status == kCCSuccess else { throw Error.derivationFailed(status) }
        return derivedKey
    }
}
enum KeychainHelper {
    static let keyTag = "com.yourapp.e2ee.masterkey"
    
    static func loadOrGenerateSymmetricKey() throws -> SymmetricKey {
        if let data = try? loadKeyData() {
            return SymmetricKey(data: data)
        } else {
            let key = SymmetricKey(size: .bits256)
            try saveKeyData(key.withUnsafeBytes { Data($0) })
            return key
        }
    }
    
    private static func saveKeyData(_ data: Data) throws {
        let queryDelete: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
        ]
        SecItemDelete(queryDelete as CFDictionary)
        
        let queryAdd: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(queryAdd as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "Keychain", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Keychain save failed: \(status)"])
        }
    }
    
    private static func loadKeyData() throws -> Data {
        let queryGet: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(queryGet as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw NSError(domain: "Keychain", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Keychain load failed: \(status)"])
        }
        return data
    }
}
struct E2EE {
    static func encrypt(_ plaintext: Data, using key: SymmetricKey) throws -> (cipher: Data, nonce: Data) {
        let nonce = AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(plaintext, using: key, nonce: nonce)
        return (sealed.ciphertext + sealed.tag, Data(nonce))
    }
}
struct BeginRecoveryResponse {
    let sessionToken: String
    let clientSaltB64: String?
}
protocol AccountRecoveryAPI {
    func beginRecovery(email: String) async throws -> BeginRecoveryResponse
    func verifyRecoveryCodeFinal(email: String, code: String, sessionToken: String) async throws
    func updatePassword(email: String,
                        encryptedNewPasswordB64: String,
                        nonceB64: String,
                        encAlgo: String,
                        clientProofB64: String,
                        clientSaltB64: String,
                        sessionToken: String) async throws
}
final class DefaultAccountRecoveryAPI: AccountRecoveryAPI {
    func beginRecovery(email: String) async throws -> BeginRecoveryResponse {
        return BeginRecoveryResponse(sessionToken: "mock-session", clientSaltB64: nil)
    }
    func verifyRecoveryCodeFinal(email: String, code: String, sessionToken: String) async throws {
    }
    func updatePassword(email: String,
                        encryptedNewPasswordB64: String,
                        nonceB64: String,
                        encAlgo: String,
                        clientProofB64: String,
                        clientSaltB64: String,
                        sessionToken: String) async throws {
    }
}
struct AccountRecoveryFlowView: View {
    @EnvironmentObject var appleSignInManager: AppleSignInManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var codesText: String = ""
    @State private var parsedCodes: [String] = []
    @State private var newPassword = ""
    @State private var step: Step = .enterEmail
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var sessionToken: String?
    @State private var verified = false
    @State private var clientSaltB64: String?
    private let api: AccountRecoveryAPI = DefaultAccountRecoveryAPI()
    private static let localizedErrorSeed: [LocalizedStringResource] = [
        "8 valid recovery codes are required. Format: XXXX-XXXX",
        "Session is invalid.",
        "Recovery verification has not been completed."
    ]
    
    enum Step {
        case enterEmail
        case enterCode
        case setNewPassword
        case done
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Account Recovery").font(.title2).bold()
            
            switch step {
            case .enterEmail:
                if #available(iOS 26.0, *) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .padding(.horizontal , 10)
                        .padding(.vertical , 10)
                        .glassEffect(.regular.interactive())
                } else {
                    // Fallback on earlier versions
                }
                Button("Continue") { Task { await beginRecovery() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
            case .enterCode:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter 8 recovery codes.")
                        .font(.headline)
                    Text("The code should be in 4-4 format: XXXX-XXXX. You can write the codes on separate lines or separate them with a space.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    TextEditor(text: $codesText)
                        .frame(minHeight: 140)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                        .padding(.top, 4)
                }
                Button("Continue") { Task { await verifyCode() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceedWithCodes())
                
            case .setNewPassword:
                SecureField("New password", text: $newPassword)
                    .textContentType(.newPassword)
                    .textFieldStyle(.roundedBorder)
                Button("Update Password") { Task { await updatePassword() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(newPassword.count < 8 || verified == false)
                
            case .done:
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.largeTitle)
                Text("Account recovery completed.")
                Button("Dismiss") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            
            if isLoading { ProgressView() }
            if let errorMessage { Text(errorMessage).foregroundColor(.red) }
        }
        .padding()
    }
    
    private func beginRecovery() async {
        await run {
            let response = try await api.beginRecovery(email: email)
            self.sessionToken = response.sessionToken
            self.clientSaltB64 = response.clientSaltB64
            self.step = .enterCode
        }
    }
    
    private func verifyCode() async {
        await run {
            let codes = parseAndValidateCodes(from: codesText)
            guard codes.count == 8 else {
                throw simple(String(localized: "8 valid recovery codes are required. Format: XXXX-XXXX"))
            }
            self.parsedCodes = codes
            guard let sessionToken else { throw simple(String(localized: "Session is invalid.")) }
            try await api.verifyRecoveryCodeFinal(email: email, code: codes.first ?? "", sessionToken: sessionToken)
            self.verified = true
            self.step = .setNewPassword
        }
    }
    
    private func updatePassword() async {
        await run {
            guard let sessionToken else { throw simple(String(localized: "Session is invalid.")) }
            guard verified else { throw simple(String(localized: "Recovery verification has not been completed.")) }
            
            let key = try KeychainHelper.loadOrGenerateSymmetricKey()
            let plain = Data(newPassword.utf8)
            let (cipher, nonce) = try E2EE.encrypt(plain, using: key)
            let encryptedB64 = cipher.base64EncodedString()
            let nonceB64 = nonce.base64EncodedString()
            let saltData: Data
            if let serverSaltB64 = clientSaltB64, let serverSalt = Data(base64Encoded: serverSaltB64) {
                saltData = serverSalt
            } else {
                saltData = randomSalt(length: 16)
                self.clientSaltB64 = saltData.base64EncodedString()
            }
            let derived = try PBKDF2Helper.deriveKey(password: newPassword, salt: saltData, iterations: 100_000, keyLength: 32)
            let clientProofB64 = derived.base64EncodedString()
            let clientSaltB64 = (self.clientSaltB64 ?? saltData.base64EncodedString())
            try await api.updatePassword(email: email,
                                         encryptedNewPasswordB64: encryptedB64,
                                         nonceB64: nonceB64,
                                         encAlgo: "AES-GCM-256",
                                         clientProofB64: clientProofB64,
                                         clientSaltB64: clientSaltB64,
                                         sessionToken: sessionToken)
            self.appleSignInManager.savePassword(self.newPassword)
            self.step = .done
        }
    }
    
    private func parseAndValidateCodes(from text: String) -> [String] {
        let separators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",;"))
        let rawParts = text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let pattern = "^[A-Za-z0-9]{4}-[A-Za-z0-9]{4}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let valid = rawParts.compactMap { part -> String? in
            let candidate = part.uppercased()
            guard let regex else { return nil }
            let range = NSRange(location: 0, length: candidate.utf16.count)
            if regex.firstMatch(in: candidate, options: [], range: range) != nil {
                return candidate
            } else {
                return nil
            }
        }
        return Array(valid.prefix(8))
    }
    private func canProceedWithCodes() -> Bool {
        parseAndValidateCodes(from: codesText).count == 8
    }
    private func randomSalt(length: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return Data(bytes)
    }
    private func run(_ work: @escaping () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await work()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    private func simple(_ msg: String) -> NSError {
        NSError(domain: "AccountRecovery", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
    }
}

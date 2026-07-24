import Foundation
import SwiftUI
import LocalAuthentication
import Combine
@MainActor
class PrivacySecurityViewModel: ObservableObject {

    @AppStorage("privacy.faceIDOn") var faceIDOn: Bool = false
    @AppStorage("privacy.twoFAOn") var twoFAOn: Bool = false
    @AppStorage("privacy.recoveryCodes") var savedRecoveryCodesJSON: String = ""
    @AppStorage("privacy.userPassword") var password: String = ""
    @Published var showingChangePasswordSheet = false
    @Published var showingRecoveryCodeSetup = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var generatedRecoveryCodes: [String]? = nil
    @Published var isPasswordSetServer: Bool = false

    let authService = AuthenticationService()
    var isPasswordSet: Bool {
        !password.isEmpty
    }

    func refreshServerPasswordState(using manager: AnyObject?) {
        guard let manager = manager as? AppleSignInManager else {
            self.isPasswordSetServer = false
            return
        }
        Task {
            self.isPasswordSetServer = await manager.hasPassword()
        }
    }
    func toggleFaceID(to newValue: Bool) async {
        let reason = newValue
        ? NSLocalizedString("Verify your biometrics to enable Face ID / Touch ID.", comment: "")
        : NSLocalizedString("Verify your biometrics to disable Face ID / Touch ID.", comment: "")
        let success = await authService.requestUserVerification(reason: reason)
        if success {
            self.faceIDOn = newValue
        } else {
            self.errorMessage = NSLocalizedString("Biometric authentication failed. Device passcode is not allowed.", comment: "")
        }
    }

    func handle2FAToggle(isOn: Bool) async {
        if isOn {
            self.showingRecoveryCodeSetup = true
        } else {
            let reason = NSLocalizedString(isOn ? "Verify your identity to enable 2FA." : "Verify your identity to disable 2FA.", comment: "")
            let success = await authService.requestUserVerification(reason: reason)
            if success {
                self.twoFAOn = false
                self.savedRecoveryCodesJSON = ""
                self.successMessage = NSLocalizedString("Two-factor authentication has been disabled.", comment: "")
            } else {
                self.errorMessage = NSLocalizedString("Authentication failed.", comment: "")
            }
        }
    }

    func generateRecoveryCodes() async {
        let reason = NSLocalizedString("Verify your identity to generate recovery codes.", comment: "")
        let success = await authService.requestUserVerification(reason: reason)
        guard success else {
            self.errorMessage = NSLocalizedString("Authentication failed.", comment: "")
            return
        }
        var codes: [String] = []
        for _ in 0..<8 {
            codes.append(createRandomCode())
        }
        self.generatedRecoveryCodes = codes
    }
    
    func saveRecoveryCodes(using manager: AppleSignInManager? = nil) {
        guard let codes = generatedRecoveryCodes else { return }

        do {
            let data = try JSONEncoder().encode(codes)
            savedRecoveryCodesJSON = String(data: data, encoding: .utf8) ?? ""
        } catch {
            errorMessage = NSLocalizedString("An error occurred while saving the codes.", comment: "")
            return
        }

        if let manager = manager {
            Task {
                do {
                    try await manager.saveEncryptedRecoveryKeys(codes)
                    self.twoFAOn = true
                    self.successMessage = NSLocalizedString("2FA has been enabled and recovery codes have been securely saved.", comment: "")
                    self.showingRecoveryCodeSetup = false
                } catch {
                    self.errorMessage = "Recovery codes could not be saved to the server.”: \(error.localizedDescription)"
                }
            }
        } else {
            twoFAOn = true
            successMessage = NSLocalizedString("2FA has been enabled and recovery codes have been saved.", comment: "")
            showingRecoveryCodeSetup = false
        }
    }

    func discardRecoveryCodes() {
        generatedRecoveryCodes = nil
    }
    
    func verifyRecoveryKeysWithServer(userInputKeys: [String], using manager: AppleSignInManager) async -> Bool {
        do {
            let ok = try await manager.verifyRecoveryKeys(userInputKeys)
            if ok {
                self.successMessage = NSLocalizedString("Recovery codes have been verified.", comment: "")
            } else {
                self.errorMessage = NSLocalizedString("Recovery codes do not match.", comment: "")
            }
            return ok
        } catch {
            self.errorMessage = "Recovery codes could not be verified: \(error.localizedDescription)"
            return false
        }
    }
    
    func fetchAndVerifyRecoveryCodes() async -> [String]? {
        let reason = NSLocalizedString("Verify your identity to view saved recovery codes.", comment: "")
        let success = await authService.requestUserVerification(reason: reason)

        guard success else {
            self.errorMessage = NSLocalizedString("Authentication failed.", comment: "")
            return nil
        }

        guard !savedRecoveryCodesJSON.isEmpty,
              let data = savedRecoveryCodesJSON.data(using: .utf8) else {
            self.errorMessage = NSLocalizedString("No saved recovery code found.", comment: "")
            return nil
        }

        do {
            let codes = try JSONDecoder().decode([String].self, from: data)
            return codes
        } catch {
            self.errorMessage = NSLocalizedString("An error occurred while reading the codes.", comment: "")
            return nil
        }
    }

    private func createRandomCode() -> String {
        let characters = "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789"
        let part1 = String((0..<4).map { _ in characters.randomElement()! })
        let part2 = String((0..<4).map { _ in characters.randomElement()! })
        return "\(part1)-\(part2)"
    }


    func savePassword(old: String, new: String, confirm: String) {
        guard !new.isEmpty, !confirm.isEmpty else {
            errorMessage = NSLocalizedString("New password fields cannot be left blank.", comment: "")
            return
        }
        guard new == confirm else {
            errorMessage = NSLocalizedString("New passwords do not match.", comment: "")
            return
        }
        guard new.count >= 4 else {
            errorMessage = NSLocalizedString("Password must be at least 4 characters.", comment: "")
            return
        }

        if isPasswordSet {
            guard !old.isEmpty else {
                errorMessage = NSLocalizedString("You must enter your current password.", comment: "")
                return
            }
            guard old == password else {
                errorMessage = NSLocalizedString("Current password is incorrect.", comment: "")
                return
            }
        }

        password = new
        successMessage = isPasswordSet
            ? NSLocalizedString("Password changed successfully.", comment: "")
            : NSLocalizedString("Password created successfully.", comment: "")
        showingChangePasswordSheet = false
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}


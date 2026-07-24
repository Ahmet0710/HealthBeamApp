import SwiftUI
import LocalAuthentication
import Combine
struct JournalSettingsView: View {
    @AppStorage("isJournalLocked") private var isJournalLocked = false
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService: AuthenticationService

    var body: some View {
        let journalLockBinding = Binding<Bool>(
            get: {
                self.isJournalLocked
            },
            set: { newValue in
                let reason = newValue
                    ? "Authenticate to enable journal protection."
                    : "Authenticate to disable journal protection."
                Task {
                    let success = await authService.requestUserVerification(reason: reason)
                    await MainActor.run {
                        if success {
                            self.isJournalLocked = newValue
                        }
                    }
                }
            }
        )

        NavigationStack {
            Form {
                Section(header: Text("Security")) {
                    Toggle("Protect Journal", isOn: journalLockBinding)
                        .tint(.customPurple)
                }
            }
            .navigationTitle("Journal Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

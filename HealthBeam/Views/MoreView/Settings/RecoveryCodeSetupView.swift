import SwiftUI
struct RecoveryCodeSetupView: View {
    @ObservedObject var viewModel: PrivacySecurityViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.generatedRecoveryCodes == nil {
                    InitialSetupView(viewModel: viewModel)
                } else {
                    CodeDisplayView(viewModel: viewModel)
                }
            }
            .navigationTitle("2 Factor Authentication ")
            .navigationBarItems(leading: Button("Dismiss") {
                viewModel.discardRecoveryCodes()
                dismiss()
            })
            .onDisappear {
                viewModel.discardRecoveryCodes()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK", role: .cancel) {
                    viewModel.clearMessages()
                }
            }, message: {
                Text(viewModel.errorMessage ?? String(localized: "Unknown error."))
                }
            )
        }
    }
}
struct InitialSetupView: View {
    @ObservedObject var viewModel: PrivacySecurityViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity)
            Text("Generate 2FA codes")
                .font(.title2).bold()
                .frame(maxWidth: .infinity)
            Text("Enabling two-step verification adds an extra layer of security to your account. In case you lose access to your device, you will be able to generate one-time recovery codes to access your account.")
            Text("It is very important to save these codes in a secure place. Each code can only be used once.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
            Spacer()
            Button(action: {
                Task {
                    await viewModel.generateRecoveryCodes()
                }
            }) {
                Text("Got it. Generate the codes.")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}
struct CodeDisplayView: View {
    @ObservedObject var viewModel: PrivacySecurityViewModel
    @State private var copied = false
    @EnvironmentObject var appleSignInManager: AppleSignInManager
    var codeColumns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Save your Recovery Codes")
                .font(.title2).bold()
                .frame(maxWidth: .infinity)
            Text("Make sure to note this code 8 in a secure place. You won't be able to see the codes again after closing this screen.")
                .multilineTextAlignment(.center)
            LazyVGrid(columns: codeColumns, spacing: 15) {
                ForEach(viewModel.generatedRecoveryCodes ?? [], id: \.self) { code in
                    Text(code)
                        .font(.system(.body, design: .monospaced).bold())
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical)
            Button(action: {
                let codesString = viewModel.generatedRecoveryCodes?.joined(separator: "\n")
                UIPasteboard.general.string = codesString
                copied = true
            }) {
                if copied {
                    Label("Copied!", systemImage: "checkmark")
                } else {
                    Label("Copy All Codes", systemImage: "doc.on.doc")
                }
            }
            .frame(maxWidth: .infinity)
            .disabled(copied)
            Spacer()
            Button(action: {
                viewModel.saveRecoveryCodes(using: appleSignInManager)
            }) {
                Text("I have saved the codes, enable 2FA")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

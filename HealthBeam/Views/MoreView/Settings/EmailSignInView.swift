import SwiftUI
struct EmailSignInView: View {
    @EnvironmentObject var accountManager: AccountManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple.opacity(0.5), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(isRegistering ? String(localized: "Create Account") : String(localized: "Sign In"))
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                
                if isRegistering {
                    TextField("Name Surname", text: $name)
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .textFieldStyle(.roundedBorder)
                }
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)
                SecureField("Password", text: $password)
                    .textContentType(isRegistering ? .newPassword : .password)
                    .textFieldStyle(.roundedBorder)
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: authenticate) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(isRegistering ? String(localized: "Register") : String(localized: "Sign In"))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled((isRegistering && (name.isEmpty || email.isEmpty || password.isEmpty)) || (!isRegistering && (email.isEmpty || password.isEmpty)) || isLoading)

                Button(isRegistering ? String(localized: "Already have an account? Sign In") : String(localized: "Don't have an account? Register")) {
                    isRegistering.toggle()
                    errorMessage = nil
                    name = ""
                }
                .font(.footnote)
                .tint(.white)
            }
            .padding()
        }
        .foregroundColor(.white)
        .onAppear {
            errorMessage = nil
        }
    }
    func authenticate() {
            isLoading = true
            errorMessage = nil
            Task {
                do {
                    if isRegistering {
                        try await accountManager.signUp(name: name, email: email, password: password)
                    } else {
                        try await accountManager.signIn(email: email, password: password)
                    }
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
            isLoading = false
        }
    }
}

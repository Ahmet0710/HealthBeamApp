import SwiftUI
import RevenueCat
import RevenueCatUI

struct HealthBeamAIView: View {
    @EnvironmentObject var viewModel: HealthBeamAIViewModel
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appleSignInManager: AppleSignInManager
    @FocusState private var isInputViewFocused: Bool
    private let typingIndicatorID = "typingIndicator"
    @State private var userInput: String = ""
    private let characterLimit = 1500

    var body: some View {
        Group {
            if userManager.isSignedIn {
                chatInterface
            } else {
                SignInPromptView()
                    .environmentObject(appleSignInManager)
            }
        }
    }

    private var chatInterface: some View {
        ZStack {
            LinearGradient(colors: [.purple.opacity(0.5), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    headerView
                    messageListView
                }
                .onTapGesture { isInputViewFocused = false }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: scrollViewProxy)
                }
                .onChange(of: viewModel.isLoading) { _, newValue in
                    if newValue { scrollToBottom(proxy: scrollViewProxy, isTyping: true) }
                }
                .onAppear { scrollToBottom(proxy: scrollViewProxy, animated: false) }
                .safeAreaInset(edge: .bottom) {
                    messageInputBar
                        .onChange(of: userInput) { _, newValue in
                            if newValue.count > characterLimit {
                                userInput = String(newValue.prefix(characterLimit))
                            }
                        }
                }
            }
        }
    }
    
    private var headerView: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                Spacer()
                Menu {
                    Toggle(isOn: $viewModel.isMemoryEnabled) {
                        Label("Memory", systemImage: "brain.head.profile")
                    }
                    Divider()
                    Button(role: .destructive, action: { viewModel.clearConversation() }) {
                        Label("Clear Chat", systemImage: "trash")
                    }
                } label: {
                    Text("Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(.ultraThinMaterial).opacity(0.4))
                        .glassEffect(.regular.interactive())
                }
            }
            .padding(.trailing, 4)
            .padding(.top, 0)

            VStack(alignment: .leading, spacing: 8) {
                Text("HealthBeam AI")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                Text("Private Cloud Compute")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal)
        .padding(.top, 28)
    }
    
    private var messageListView: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.messages) { message in
                MessageBubble(message: message)
            }
            if viewModel.isLoading {
                TypingIndicatorBubble()
                    .id(typingIndicatorID)
            }
        }
        .padding(.vertical)
    }
    
    private var messageInputBar: some View {
        HStack(spacing: 8) {
            TextField("Type your message here", text: $userInput, axis: .vertical)
                .lineLimit(1...5)
                .padding(.vertical, 11)
                .padding(.horizontal)
                .focused($isInputViewFocused)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.purple)
            }
            .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.thinMaterial)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true, isTyping: Bool = false) {
        let idToScroll: AnyHashable?
        if isTyping {
            idToScroll = typingIndicatorID
        } else {
            idToScroll = viewModel.messages.last?.id
        }
        guard let id = idToScroll else { return }
        if animated {
            withAnimation(.spring()) { proxy.scrollTo(id, anchor: .bottom) }
        } else {
            proxy.scrollTo(id, anchor: .bottom)
        }
    }

    private func send() {
        viewModel.sendMessage(userInput: userInput)
        userInput = ""
    }
}

struct SignInPromptView: View {
    @EnvironmentObject var appleSignInManager: AppleSignInManager
    @EnvironmentObject var authService: AuthenticationService
    @State private var showEmailSignIn = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple.opacity(0.5), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill").font(.system(size: 60)).foregroundColor(.purple)
                Text("Please Sign In").font(.title2).fontWeight(.bold).multilineTextAlignment(.center).foregroundColor(.white)
                Text("Access the amazing features by signing in to your account.").font(.headline).multilineTextAlignment(.center).foregroundColor(.white.opacity(0.8)).padding(.horizontal)
                
                SwiftUISignInWithAppleButton().frame(height: 50)
                
                Divider()
                
                Button("Sign in with Email") {
                    showEmailSignIn = true
                }
                .font(.headline)
                .tint(.white)

            }
            .padding(.horizontal, 40)
        }
        .sheet(isPresented: $showEmailSignIn) {
            EmailSignInView().environmentObject(authService)
        }
    }
}
struct MessageBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 40) }
            Text(message.text)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .foregroundColor(.white)
                .background(message.isFromUser ? Color.purple.opacity(0.8) : Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            if !message.isFromUser { Spacer(minLength: 40) }
        }.padding(.horizontal)
    }
}
struct TypingIndicatorBubble: View {
    @State private var scale: CGFloat = 0.5
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle().frame(width: 8, height: 8).scaleEffect(scale)
                Circle().frame(width: 8, height: 8).scaleEffect(scale).animation(.easeInOut(duration: 0.6).repeatForever().delay(0.2), value: scale)
                Circle().frame(width: 8, height: 8).scaleEffect(scale).animation(.easeInOut(duration: 0.6).repeatForever().delay(0.4), value: scale)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .onAppear { scale = 1 }
            Spacer()
        }
        .padding(.horizontal)
    }
}

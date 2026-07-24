// MARK: - BeamAIViewModel.swift
import Foundation
import Combine
import SwiftUI
import FirebaseAuth

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
class HealthBeamAIViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var isMemoryEnabled: Bool = true

    private let userManager: UserManager
    private var cancellables = Set<AnyCancellable>()
    private let persistenceManager = PersistenceManager()

    #if canImport(FoundationModels)
    @available(iOS 18.0, *)
    private var aiSession: LanguageModelSession? {
        get { _aiSession as? LanguageModelSession }
        set { _aiSession = newValue }
    }
    #endif
    private var _aiSession: Any?

    init(userManager: UserManager) {
        self.userManager = userManager
        loadMessages()
        
        $messages
            .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
            .sink { [weak self] updatedMessages in
                guard let self = self, let userId = Auth.auth().currentUser?.uid else { return }
                if updatedMessages.count > 1 {
                    self.persistenceManager.save(messages: updatedMessages, for: userId)
                }
            }
            .store(in: &cancellables)
    }

    private func loadMessages() {
        if let userId = Auth.auth().currentUser?.uid, let loaded = persistenceManager.load(for: userId) {
            self.messages = loaded
        } else {
            let welcomeMessage = "Hello! I am HealthBeam AI, powered by Apple Private Cloud Compute. How can I help you with your healthy living goals today?"
            messages.append(ChatMessage(text: welcomeMessage, isFromUser: false))
        }
    }
    
    #if canImport(FoundationModels)
    @available(iOS 18.0, *)
    private func getSession() -> LanguageModelSession {
        if let session = aiSession, isMemoryEnabled {
            return session
        }
        
        let session = LanguageModelSession(model: PrivateCloudComputeLanguageModel(), instructions: HealthBeamAIConstants.systemInstructions)
        if isMemoryEnabled {
            self.aiSession = session
        }
        return session
    }
    #endif

    func sendMessage(userInput: String) {
        let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty, !isLoading else { return }
        
        if !userManager.isSignedIn {
            if messages.last?.isFromUser == true {
                messages.append(ChatMessage(text: "Please sign in to use HealthBeam AI.", isFromUser: false))
            }
            return
        }

        let userMessage = ChatMessage(text: trimmedInput, isFromUser: true)
        messages.append(userMessage)
        isLoading = true

        Task {
            #if canImport(FoundationModels)
            if #available(iOS 18.0, *) {
                do {
                    let session = getSession()
                    let response = try await session.respond(to: trimmedInput)
                    let aiMessage = ChatMessage(text: response.text, isFromUser: false)
                    messages.append(aiMessage)
                } catch {
                    messages.removeLast()
                    messages.append(ChatMessage(text: "Failed to connect to Apple Private Cloud Compute: \(error.localizedDescription)", isFromUser: false))
                }
            } else {
                messages.removeLast()
                messages.append(ChatMessage(text: "HealthBeam AI requires a newer version of iOS that supports Apple Foundation Models.", isFromUser: false))
            }
            #else
            messages.removeLast()
            messages.append(ChatMessage(text: "HealthBeam AI requires iOS with Apple Foundation Models capabilities. Please update Xcode and iOS.", isFromUser: false))
            #endif
            
            isLoading = false
        }
    }
    
    func clearConversation() {
        messages.removeAll()
        let welcomeMessage = "Hello! I am HealthBeam AI, powered by Apple Private Cloud Compute. How can I help you with your healthy living goals today?"
        messages.append(ChatMessage(text: welcomeMessage, isFromUser: false))
        
        if let userId = Auth.auth().currentUser?.uid {
            persistenceManager.delete(for: userId)
        }
        
        #if canImport(FoundationModels)
        if #available(iOS 18.0, *) {
            self.aiSession = nil
        }
        #endif
    }
}

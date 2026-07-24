import AppIntents
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 16.0, *)
struct AskHealthBeamIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask HealthBeam AI"
    static var description = IntentDescription("Ask a health or fitness question to HealthBeam AI.")
    
    @Parameter(title: "Question", description: "What would you like to ask?")
    var question: String
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        #if canImport(FoundationModels)
        if #available(iOS 18.0, *) {
            do {
                let session = LanguageModelSession(model: PrivateCloudComputeLanguageModel(), instructions: HealthBeamAIConstants.systemInstructions)
                let response = try await session.respond(to: question)
                return .result(dialog: IntentDialog(stringLiteral: response.text))
            } catch {
                return .result(dialog: IntentDialog(stringLiteral: "I'm sorry, I couldn't reach the Private Cloud Compute servers. Please try again."))
            }
        } else {
            return .result(dialog: IntentDialog(stringLiteral: "HealthBeam AI requires a newer version of iOS that supports Apple Foundation Models."))
        }
        #else
        return .result(dialog: IntentDialog(stringLiteral: "HealthBeam AI requires iOS with Apple Foundation Models capabilities. Please update Xcode and iOS."))
        #endif
    }
}

@available(iOS 16.0, *)
struct HealthBeamShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskHealthBeamIntent(),
            phrases: [
                "Ask \(.applicationName) about \(\.$question)",
                "Consult \(.applicationName) for \(\.$question)",
                "Tell \(.applicationName) \(\.$question)"
            ],
            shortTitle: "Ask HealthBeam",
            systemImageName: "sparkles"
        )
    }
}

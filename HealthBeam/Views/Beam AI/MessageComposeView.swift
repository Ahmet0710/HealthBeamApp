import SwiftUI
import MessageUI

struct MessageComposeView: UIViewControllerRepresentable {
    typealias UIViewControllerType = MFMessageComposeViewController

    var recipients: [String] = []
    var body: String? = nil
    var subject: String? = nil
    var attachments: [(data: Data, uti: String, filename: String)] = []
    var completion: (MessageComposeResult) -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.messageComposeDelegate = context.coordinator
        vc.recipients = recipients
        vc.body = body
        if MFMessageComposeViewController.canSendSubject() {
            vc.subject = subject
        }
        attachments.forEach { item in
            vc.addAttachmentData(item.data, typeIdentifier: item.uti, filename: item.filename)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let completion: (MessageComposeResult) -> Void
        init(completion: @escaping (MessageComposeResult) -> Void) {
            self.completion = completion
        }
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true) { [completion] in
                completion(result)
            }
        }
    }
}
struct MessageComposeDemoView: View {
    @State private var showComposer = false
    @State private var canSend = MFMessageComposeViewController.canSendText()
    @State private var lastResult: MessageComposeResult? = nil

    var body: some View {
        VStack(spacing: 16) {
            Text("MFMessageComposeViewController Demo")
                .font(.title2.bold())

            if !canSend {
                Text("This device cannot send SMS/iMessage.")
                    .foregroundStyle(.secondary)
            }

            Button {
                showComposer = true
            } label: {
                Label("Send Messages", systemImage: "message.fill")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(.blue.gradient))
                    .foregroundStyle(.white)
            }
            .disabled(!canSend)
            .sheet(isPresented: $showComposer) {
                MessageComposeView(
                    recipients: ["5551234567"],
                    body: "Hello This is a test message.",
                    subject: "HealthBeam AI",
                    attachments: []
                ) { result in
                    lastResult = result
                }
                .ignoresSafeArea()
            }

            if let result = lastResult {
                Text("Results: \(describe(result))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    private func describe(_ result: MessageComposeResult) -> String {
        switch result {
        case .sent: return "Send"
        case .cancelled: return "Canceled"
        case .failed: return "Failed"
        @unknown default: return "Unspecified"
        }
    }
}

#Preview {
    NavigationView {
        MessageComposeDemoView()
            .navigationTitle("Send message")
    }
}

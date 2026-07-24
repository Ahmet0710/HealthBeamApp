import SwiftUI

// MARK: - Models

struct WhatsNewItem: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let titleKey: LocalizedStringKey
    let descriptionKey: LocalizedStringKey
}

struct WhatsNewVersion {
    let version: String
    let items: [WhatsNewItem]
}

// MARK: - Data (ALL versions stay here)

private let whatsNewData: [WhatsNewVersion] = [

    WhatsNewVersion(version: "1.0.4", items: [
        WhatsNewItem(
            icon: "face.smiling",
            color: .orange,
            titleKey: "Richer mood insights",
            descriptionKey: "Understand emotional trends more clearly with improved mood tracking."
        ),
        WhatsNewItem(
            icon: "waveform.path.ecg",
            color: .purple,
            titleKey: "Precise stress tracking",
            descriptionKey: "Track stress more accurately based on your personal patterns."
        ),
        WhatsNewItem(
            icon: "bolt.heart.fill",
            color: .red,
            titleKey: "Stronger Health Signals",
            descriptionKey: "Health Signals now deliver more actionable feedback."
        ),
        WhatsNewItem(
            icon: "paintbrush.fill",
            color: .blue,
            titleKey: "Ongoing UI refinements",
            descriptionKey: "Visual updates improve clarity and make the experience cleaner across the app."
        )
    ]),

    // ✅ OLD VERSION (DO NOT DELETE)
    WhatsNewVersion(version: "1.0.3", items: [
        WhatsNewItem(
            icon: "ellipsis.circle.fill",
            color: .blue,
            titleKey: "More Section has new tabs",
            descriptionKey: "New features has added to More section.You might wanna check that out. 🤩"
        ),
        WhatsNewItem(
            icon: "pills.fill",
            color: .pink,
            titleKey: "Medication is here",
            descriptionKey: "You can now schedule your meds in HealthBeamApp. So cool! 😎"
        ),
        WhatsNewItem(
            icon: "heart.fill",
            color: .red,
            titleKey: "Heart",
            descriptionKey: "You're gonna love the new Heart in More section ❤️"
        ),
        WhatsNewItem(
            icon: "apple.meditate",
            color: .green,
            titleKey: "Mindfulness",
            descriptionKey: "6 new categories for relaxing and calming. Meditate whenever you want.😌"
        ),
        WhatsNewItem(
            icon: "lock.fill",
            color: .gray,
            titleKey: "No ads & No Tracking, Never.",
            descriptionKey: "This is not new but I just wanted to let you know that this app has no ads and never tracks you. So you can enjoy.😉"
        )
    ])
]

// MARK: - Helper

func currentAppVersionString() -> String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
}

func hasWhatsNewContentForCurrentVersion() -> Bool {
    currentWhatsNewVersion() != nil
}

private func currentWhatsNewVersion() -> WhatsNewVersion? {
    let current = currentAppVersionString()
    return whatsNewData.first(where: { $0.version == current })
}

// MARK: - View

struct WhatsNew: View {
    var onContinue: (() -> Void)? = nil

    var body: some View {
        VStack {
            
            // Header
            HStack(alignment: .center, spacing: 6) {
                Image("AppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 8)

                VStack(spacing: 0) {
                    Text("What's New in HealthBeamApp")
                        .font(.system(.title2, weight: .bold))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 40)
            .padding(.bottom, 24)

            // Dynamic Content
            if let version = currentWhatsNewVersion() {
                VStack(spacing: 28) {
                    ForEach(version.items) { item in
                        HStack {
                            Image(systemName: item.icon)
                                .symbolRenderingMode(.multicolor)
                                .foregroundStyle(item.color)
                                .font(.system(.title))
                                .frame(width: 60, height: 50)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.titleKey)
                                    .font(.system(.footnote, weight: .semibold))

                                Text(item.descriptionKey)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Text("You're up to date.")
                        .font(.system(.headline, weight: .semibold))

                    Text("No release notes are available for this version yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)
            }

            Spacer()

            // Continue Button
            Button(action: { onContinue?() }) {
                Text("Continue")
                    .font(.system(.callout, weight: .semibold))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 53)
        .padding(.horizontal, 29)
    }
}

// MARK: - Presenter (UNCHANGED logic, works perfectly)

struct WhatsNewPresenter: ViewModifier {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("lastWhatsNewShownVersion") private var lastWhatsNewShownVersion: String = ""
    @AppStorage("hasShownWhatsNewAtLeastOnce") private var hasShownWhatsNewAtLeastOnce = false
    @State private var shouldShowWhatsNew = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard hasCompletedOnboarding else { return }

                let current = currentAppVersionString()

                if lastWhatsNewShownVersion != current || !hasShownWhatsNewAtLeastOnce {
                    shouldShowWhatsNew = true
                }
            }
            .sheet(isPresented: $shouldShowWhatsNew) {
                WhatsNew {
                    let current = currentAppVersionString()
                    lastWhatsNewShownVersion = current
                    hasShownWhatsNewAtLeastOnce = true
                    shouldShowWhatsNew = false
                }
            }
    }
}

// MARK: - Extension

extension View {
    func presentsWhatsNewAfterOnboarding() -> some View {
        self.modifier(WhatsNewPresenter())
    }
}

// MARK: - Preview

#Preview {
    WhatsNew()
}

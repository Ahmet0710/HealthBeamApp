import SwiftUI
enum OnboardingStep: CaseIterable {
    case welcome, workouts, nutrition, ai, sleep, more, privacy, notifications, final
}
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @State private var currentStep: OnboardingStep = .welcome
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .welcome: welcomeView
            case .workouts: workoutsView
            case .nutrition: nutritionView
            case .ai: aiView
            case .sleep: sleepView
            case .more: moreView
            case .privacy: privacyView
            case .notifications: notificationsView
            case .final: finalView
            }
        }
        .animation(.easeInOut, value: currentStep)
        .transition(.slide)
        .preferredColorScheme(.dark)
    }
    
    private func goToNextStep() {
        if let idx = OnboardingStep.allCases.firstIndex(of: currentStep),
           idx + 1 < OnboardingStep.allCases.count {
            currentStep = OnboardingStep.allCases[idx + 1]
        } else {
            hasCompletedOnboarding = true
        }
    }
}
struct OnboardingPage: View {
    let gradient: [Color]
    let title: String
    let subtitle: String?
    let titleColor: Color
    let description: String?
    let attributedDescription: AttributedString?
    let buttonColor: Color
    let buttonText: String
    let action: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 25) {
                Spacer()
                
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.leading)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.largeTitle.bold())
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.leading)
                }
                
                if let attributedDescription {
                    Text(attributedDescription)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .padding(.trailing, 50)
                } else if let description {
                    Text(description)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .padding(.trailing, 50)
                }
                
                Spacer()
                
                Button(action: action) {
                    Text(buttonText)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(buttonColor)
                        .cornerRadius(20)
                        .glassEffect(.regular.interactive())
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 60)
        }
    }
}
extension OnboardingView {
    var welcomeView: some View {
        ZStack {
            LinearGradient(colors: [.red.opacity(0.3), .black],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 25) {
                Spacer()
                Image("AppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180 , height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
                    .shadow(color: .white.opacity(0.3), radius: 15, x: 0, y: 10)
                Text(String(localized: "Welcome to HealthBeamApp"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                Text(String(localized: "Designed with the all-new iOS 26 architecture.\n\nWith the Liquid Glass design, HealthBeam comes with a refreshing new look. \n\nAlso this button is liquid glass. 👇 "))
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, 50)
                Spacer()
                
                Button(action: { goToNextStep() }) {
                    Text(String(localized: "Let’s Begin"))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.3))
                        .cornerRadius(20)
                        .glassEffect(.regular.interactive())
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 60)
        }
    }
    var workoutsView: some View {
        OnboardingPage(
            gradient: [.black,.black, .red],
            title: String(localized: "Workouts 🏃‍♀️🏃‍♂️🤸‍♂️"),
            subtitle: nil,
            titleColor: .red.opacity(0.7),
            description: String(localized: "Here you can see your overall progress with rich insights. \n\nTrack your runs, exercises, and other physical activities. \n\nAchieve your personalized goals and monitor your improvements over time to stay motivated and consistent."),
            attributedDescription: nil,
            buttonColor: .red.opacity(0.3),
            buttonText: String(localized: "Continue"),
            action: { goToNextStep() }
        )
    }
    var nutritionView: some View {
        OnboardingPage(
            gradient: [.black,.black,.green,],
            title: String(localized: "Nutrition 🥗 🍎 🥕 "),
            subtitle: String(localized: "Water 💧"),
            titleColor: .green.opacity(0.7),
            description: String(localized: "Track your meals and get a better understanding of your nutrition. You can log everything you eat. \n\nTrack your water intake, and discover patterns to improve your nutrition. \n\nMake informed choices and achieve your health goals."),
            attributedDescription: nil,
            buttonColor: .green.opacity(0.3),
            buttonText: String(localized: "Continue"),
            action: { goToNextStep() }
        )
    }
    var aiView: some View {
        let aiDescription = String(localized: "Your fitness AI coach guides you on your wellness journey. \n\nJoin and discover what you can do. \n\nAsk anything that comes up on your mind for fitness and health. \n\nHealthbeam AI can give you tips and recommendations while protecting your privacy. \n\nMake smarter decisions and stay on track with your goals effortlessly- Remember This is just the beginning.")
        var attributed = AttributedString(aiDescription)
        attributed.font = .body
        return OnboardingPage(
            gradient: [.black, .black, .purple],
            title: String(localized: "HealthBeam AI ⚡️"),
            subtitle: nil,
            titleColor: .purple.opacity(0.7),
            description: nil,
            attributedDescription: attributed,
            buttonColor: .purple.opacity(0.3),
            buttonText: String(localized: "Continue"),
            action: { goToNextStep() }
        )
    }
    var sleepView: some View {
        OnboardingPage(
            gradient: [.black,.black, .blue],
            title: String(localized: "Sleep 🌌 😴 🛌"),
            subtitle: nil,
            titleColor: .blue.opacity(0.3),
            description: String(localized: "Understand your sleep patterns to improve recovery and energy. \n\nTrack your nightly rest, learn about sleep quality, and receive tips to optimize your sleep schedule for a healthier lifestyle. \n\nCompare your sleep trends with important metrics."),
            attributedDescription: nil,
            buttonColor: .blue.opacity(0.3),
            buttonText: String(localized: "Continue"),
            action: { goToNextStep() }
        )
    }
    var moreView: some View {
        let rawString = String(localized: "Here we made lots of things that you’ll enjoy. Explore features like \n\nAchievements \nHabits \nMood \nHealth Signals \nStress  \nJournal  \nMeasurements \nMindfulness \nHeart \nMedications \n\nThe more you discover, the more you’ll enjoy HealthBeam.")
        var attributed = AttributedString(rawString)
        
        if let range = attributed.range(of: String(localized: "Achievements")) {
            attributed[range].foregroundColor = .yellow
        }
        if let range = attributed.range(of: String(localized: "Habits")) {
            attributed[range].foregroundColor = .blue
        }
        if let range = attributed.range(of: String(localized: "Mood")) {
                attributed[range].foregroundColor = .teal
        }
        if let range = attributed.range(of: String(localized: "Health Signals")) {
                attributed[range].foregroundColor = .mint
        }
        if let range = attributed.range(of: String(localized: "Stress")) {
                    attributed[range].foregroundColor = .brown
        }
        if let range = attributed.range(of: String(localized: "Journal")) {
            attributed[range].foregroundColor = .purple
        }
        if let range = attributed.range(of: String(localized: "Measurements")) {
            attributed[range].foregroundColor = .orange
        }
        if let range = attributed.range(of: String(localized: "Mindfulness")) {
            attributed[range].foregroundColor = .green
        }
        
        if let range = attributed.range(of: String(localized: "Heart")) {
                attributed[range].foregroundColor = .red
        }
        if let range = attributed.range(of: String(localized: "Medications")) {
                attributed[range].foregroundColor = .pink
        }
        return OnboardingPage(
            gradient: [.black,.black, .gray],
            title: String(localized: "And there is MORE 🌟😍🤩"),
            subtitle: nil,
            titleColor: .white.opacity(0.7),
            description: nil,
            attributedDescription: attributed,
            buttonColor: .gray.opacity(0.3),
            buttonText: String(localized: "Continue"),
            action: { goToNextStep() }
        )
    }
    var privacyView: some View {
           ZStack {
               LinearGradient(colors: [.black, .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                   .ignoresSafeArea()
               ScrollView(.vertical, showsIndicators: false) {
                   VStack(alignment: .leading, spacing: 35) {
                       Spacer().frame(height: 70)
                       Text(String(localized: "You are in control of your privacy."))
                           .font(.system(size: 28, weight: .bold))
                           .foregroundColor(.white)
                           .padding(.bottom, 8)
                           .fixedSize(horizontal: false, vertical: true)
                           .multilineTextAlignment(.leading)
                           .frame(maxWidth: .infinity, alignment: .leading)
                       VStack(spacing: 24) {
                           Label {
                               Text(String(localized: "No ads -Ever. 🚫📺 HealthBeam has 0 ad policy."))
                                   .font(.headline.weight(.semibold))
                                   .foregroundColor(.white.opacity(0.92))
                                   .fixedSize(horizontal: false, vertical: true)
                                   .multilineTextAlignment(.leading)
                                   .frame(maxWidth: .infinity, alignment: .leading)
                           } icon: {
                               Circle()
                                   .fill(Color.white.opacity(0.8))
                                   .frame(width: 10, height: 10)
                           }
                           Label {
                               Text(String(localized: "We don't and never will collect your health data- That's a promise.🙂"))
                                   .font(.headline.weight(.semibold))
                                   .foregroundColor(.white.opacity(0.92))
                                   .fixedSize(horizontal: false, vertical: true)
                                   .multilineTextAlignment(.leading)
                                   .frame(maxWidth: .infinity, alignment: .leading)
                           } icon: {
                               Circle()
                                   .fill(Color.white.opacity(0.8))
                                   .frame(width: 10, height: 10)
                           }
                           Label {
                               Text(String(localized: "All account informations (via Sign in with Apple) is end-to-end encrypted."))
                                   .font(.headline.weight(.semibold))
                                   .foregroundColor(.white.opacity(0.92))
                                   .fixedSize(horizontal: false, vertical: true)
                                   .multilineTextAlignment(.leading)
                                   .frame(maxWidth: .infinity, alignment: .leading)
                           } icon: {
                               Circle()
                                   .fill(Color.white.opacity(0.8))
                                   .frame(width: 10, height: 10)
                           }
                           Label {
                               Text(String(localized: "HealthBeam AI provides personalized health insights while keeping your data fully anonymous —That's Privacy 🔒."))
                                   .font(.headline.weight(.semibold))
                                   .foregroundColor(.white.opacity(0.92))
                                   .fixedSize(horizontal: false, vertical: true)
                                   .multilineTextAlignment(.leading)
                                   .frame(maxWidth: .infinity, alignment: .leading)
                           } icon: {
                               Circle()
                                   .fill(Color.white.opacity(0.8))
                                   .frame(width: 10, height: 10)
                           }
                           Label {
                               Text(String(localized: "To give you best experience we need your permission."))
                                   .font(.headline.weight(.semibold))
                                   .foregroundColor(.white.opacity(0.92))
                                   .fixedSize(horizontal: false, vertical: true)
                                   .multilineTextAlignment(.leading)
                                   .frame(maxWidth: .infinity, alignment: .leading)
                           } icon: {
                               Circle()
                                   .fill(Color.white.opacity(0.8))
                                   .frame(width: 10, height: 10)
                           }
                       }
                       Spacer().frame(height: 100)
                       
                   }
                   .padding(.horizontal, 32)
                   .padding(.bottom, 50)
               }
               VStack {
                   Spacer()
                   Button(action: {
                       Task {
                           _ = try? await healthKitManager.requestAuthorization()
                           goToNextStep()
                       }
                   }) {
                       Text(String(localized: "Continue"))
                           .font(.title3.bold())
                           .foregroundColor(.white)
                           .padding()
                           .frame(maxWidth: .infinity)
                           .background(Color.black.opacity(0.85))
                           .cornerRadius(18)
                           .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white, lineWidth: 1.2))
                           .glassEffect(.regular.interactive())
                   }
                   .padding(.horizontal, 32)
                   .padding(.bottom, 50)
               }
               .ignoresSafeArea(.all, edges: .bottom)
           }
       }
    var notificationsView: some View {
        OnboardingPage(
            gradient: [.black,.black, .orange],
            title: String(localized: "Stay Notified."),
            subtitle: nil,
            titleColor: .orange.opacity(0.7),
            description: String(localized: "To notify you, we need permission. \n\nSo you never miss important reminders. \n\nYou can always enable or disable it on your settings. \n\nTo recieve important updates we highly recommened to enable it."),
            attributedDescription: nil,
            buttonColor: .orange.opacity(0.3),
            buttonText: String(localized: "Enable Notifications"),
            action: {
                NotificationManager.shared.requestAuthorization()
                goToNextStep()
            }
        )
    }
    var finalView: some View {
        OnboardingPage(
            gradient: [.black, .purple.opacity(0.6)],
            title: String(localized: "Welcome to HealthBeamApp"),
            subtitle: nil,
            titleColor: .purple.opacity(0.7),
            description: String(localized: "I’m absolutely thrilled to share this revolutionary app with you and I am honored to bring you an all-new, iOS 26 experience like never before!. \n\nIt is nice to see you with us.😎"),
            attributedDescription: nil,
            buttonColor: .purple.opacity(0.3),
            buttonText: String(localized: "Welcome to HealthBeamApp"),
            action: { hasCompletedOnboarding = true }
        )
        .font(.headline)
    }
}

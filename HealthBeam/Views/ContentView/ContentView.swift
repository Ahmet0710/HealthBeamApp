import SwiftUI
import Combine
import Charts

private enum Tab: Hashable {
    case workouts, nutrition, beam, sleep, more
}

struct ContentView: View {
    // MARK: - Environment & State
    @EnvironmentObject var reviewManager: AppReviewManager
    @State private var selectedTab: Tab = .workouts
    @StateObject private var habitsViewModel = HabitsViewModel()
    @StateObject private var nutritionViewModel = NutritionViewModel()
    @StateObject private var measurementSystemManager = MeasurementSystemManager()
    @StateObject private var sleepViewModel = SleepViewModel()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        VStack(spacing: 0) {
            if reviewManager.isDemoMode {
                demoBanner
            }
            TabView(selection: $selectedTab) {
                WorkoutsView()
                    .tabItem {
                        Image(systemName: selectedTab == .workouts ? "figure.walk.circle.fill" : "figure.walk.circle")
                            .environment(\.symbolVariants, .none)
                        Text("Workouts")
                    }
                    .tag(Tab.workouts)

                NutritionView()
                    .tabItem {
                        Image(systemName: selectedTab == .nutrition ? "leaf.fill" : "leaf")
                            .environment(\.symbolVariants, .none)
                        Text("Nutrition")
                    }.tag(Tab.nutrition)
                
                HealthBeamAIView()
                    .tabItem {
                        Image(systemName: selectedTab == .beam ? "bolt.fill" : "bolt")
                            .environment(\.symbolVariants, .none)
                        Text("HealthBeam AI")
                    }
                    .tag(Tab.beam)

                SleepView()
                    .tabItem {
                        Image(systemName: selectedTab == .sleep ? "moon.fill" : "moon")
                            .environment(\.symbolVariants, .none)
                        Text("Sleep")
                    }
                    .tag(Tab.sleep)

                MoreView()
                    .tabItem {
                        Image(systemName: selectedTab == .more ? "ellipsis.circle.fill" : "ellipsis.circle")
                            .environment(\.symbolVariants, .none)
                        Text("More")
                    }
                    .tag(Tab.more)
            }
            .environmentObject(reviewManager)
            .accentColor(tintColor(for: selectedTab)) // SwiftUI tint yönetimi
            .preferredColorScheme(.dark)
        }
        .presentsWhatsNewAfterOnboarding()
        .environmentObject(reviewManager)
    }
    
    private var demoBanner: some View {
        Text("Demo Mode Active")
            .font(.caption2).bold()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .foregroundColor(.black)
    }
}

private func tintColor(for tab: Tab) -> Color {
    switch tab {
    case .workouts: return .red
    case .nutrition: return .green
    case .beam: return .purple
    case .sleep: return Color(red: 0.1, green: 0.2, blue: 0.7)
    case .more: return .blue
    }
}

// MARK: - Preview Güncelleme
#Preview("ContentView") {
    let userManager = UserManager()
    let healthBeamAIViewModel = HealthBeamAIViewModel(userManager: userManager)
    
    ContentView()
        .environmentObject(AppReviewManager.shared)
        .environmentObject(HabitsViewModel())
        .environmentObject(NutritionViewModel())
        .environmentObject(AchievementsViewModel())
        .environmentObject(MeasurementSystemManager())
        .environmentObject(healthBeamAIViewModel)
        .environmentObject(userManager)
        .environmentObject(AppleSignInManager())
}

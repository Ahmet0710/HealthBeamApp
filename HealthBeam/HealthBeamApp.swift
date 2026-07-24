import SwiftUI
import FirebaseCore
import SwiftData
import RevenueCat
import UIKit
import CoreData
import UserNotifications

@main
struct HealthBeamApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // MARK: - ViewModels
    @StateObject private var appReviewManager = AppReviewManager.shared // DEMO MODU EKLEMESİ
    @StateObject private var userManager: UserManager
    @StateObject private var beamAIViewModel: HealthBeamAIViewModel
    @StateObject private var habitsViewModel = HabitsViewModel()
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var achievementsViewModel = AchievementsViewModel()
    @StateObject private var nutritionViewModel = NutritionViewModel()
    @StateObject private var authService = AuthenticationService()
    @StateObject private var appleSignInManager = AppleSignInManager()
    @StateObject private var privacyViewModel = PrivacySecurityViewModel()
    @StateObject private var accountManager = AccountManager()
    @StateObject private var audioManager = AudioManager()
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("privacy.faceIDOn") var isFaceIDEnabled: Bool = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self, JournalEntry.self, MoodEntry.self, Meal.self, MealPlan.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("ModelContainer oluşturulamadı: \(error)")
        }
    }()
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasAttemptedAuthentication = false
    
    init() {
        FirebaseApp.configure()
        Purchases.logLevel = .debug
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: "appl_ntYgZUHjQcakfUvUwSOSbpsnPuK")
                .build()
        )
        let um = UserManager()
        _userManager = StateObject(wrappedValue: um)
        _beamAIViewModel = StateObject(wrappedValue: HealthBeamAIViewModel(userManager: um))
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            mainAppView
        }
        .modelContainer(sharedModelContainer)
    }
    
    var mainAppView: some View {
        ZStack {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .blur(radius: (!isFaceIDEnabled || authService.isUnlocked) ? 0 : 10)
            .disabled(isFaceIDEnabled && !authService.isUnlocked)
            
            if isFaceIDEnabled && !authService.isUnlocked {
                LockedView(onUnlock: {
                    Task { await authService.authenticate() }
                })
                .transition(.opacity)
            }
        }
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
        .environmentObject(habitsViewModel)
        .environmentObject(nutritionViewModel)
        .environmentObject(healthKitManager)
        .environmentObject(achievementsViewModel)
        .environmentObject(authService)
        .environmentObject(beamAIViewModel)
        .environmentObject(appleSignInManager)
        .environmentObject(MeasurementSystemManager())
        .environmentObject(userManager)
        .environmentObject(audioManager)
        .environmentObject(privacyViewModel)
        .environmentObject(accountManager)
        .environmentObject(appReviewManager) // TÜM EKRANLARA ERİŞİM VERİLDİ
        .preferredColorScheme(.dark)
        .onAppear {
            if !isFaceIDEnabled { authService.isUnlocked = true }
        }
    }
}
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

import SwiftUI
import Combine
import HealthKit
import SwiftData

struct MainTabView: View {
    // App'ten gelen ortak ses yöneticisini yakalıyoruz
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        ZStack(alignment: .bottom) { // ✅ ZStack ile üst üste koyuyoruz
            
            // --- 1. MEVCUT TAB YAPISI ---
            TabView {
                NavigationStack {
                    HabitsView()
                }
                .tabItem {
                    Label("Habits", systemImage: "checkmark.square")
                }
                
                NavigationStack {
                    DiscoverView()
                }
                .tabItem {
                    Label("Mindfulness", systemImage: "wind")
                }
                
                NavigationStack {
                    ProgressDashboardView() // ProgressView yerine Dashboard'u çağırdım (Dosya ismin öyle)
                }
                .tabItem {
                    Label("Progress", systemImage: "chart.bar")
                }
            }
            .accentColor(.green) // TabBar rengi
            
            // --- 2. MINI PLAYER (SÜREKLİ GÖRÜNEN) ---
            // Eğer bir meditasyon seçiliyse göster
            if audioManager.currentMeditationID != nil {
                MiniPlayerView()
                    .padding(.bottom, 50) // TabBar'ın hemen üzerinde dursun
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: audioManager.currentMeditationID)
                    .zIndex(1) // En üst katmanda kalsın
            }
        }
        // Diğer Environment objen
        .environmentObject(MeasurementSystemManager())
    }
}

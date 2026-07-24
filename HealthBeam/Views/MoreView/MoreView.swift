import SwiftUI
struct MoreView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // --- 1. DİNAMİK RENKLİ ARKA PLAN ---
                Color(red: 0.05, green: 0.08, blue: 0.12).ignoresSafeArea()
                
                GeometryReader { proxy in
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 400, height: 400)
                        .blur(radius: 70)
                        .offset(x: -100, y: -100)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.25))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: proxy.size.width - 150, y: 200)
                    
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(x: 50, y: proxy.size.height - 250)
                }
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("More")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 25)
                            .padding(.top, 20)
                        
                        // --- 2. RENKLİ GLASS KARTLAR ---
                        VStack(spacing: 14) {
                            MoreSectionCard(icon: "star.fill", iconColor: Color(red: 0.96, green: 0.67, blue: 0.18), title: "Achievements", subtitle: "View your milestones", destination: AchievementsViews())
                            
                            MoreSectionCard(icon: "checkmark.circle.fill", iconColor: .blue, title: "Habits", subtitle: "Track daily routines", destination: HabitsView())
                            
                            MoreSectionCard(icon: "face.smiling.inverse", iconColor: .teal, title: "Mood", subtitle: "Understand emotional trends", destination: MoodTrackingView().toolbar(.hidden, for: .tabBar))

                            MoreSectionCard(icon: "waveform.badge.magnifyingglass", iconColor: .cyan, title: "Health Signals", subtitle: "Turn signals into actions", destination: HealthSignalsView().toolbar(.hidden, for: .tabBar))
                            
                            MoreSectionCard(icon: "bolt.heart.fill", iconColor: Color(red: 0.92, green: 0.45, blue: 0.24), title: "Stress", subtitle: "Analyze watch-based strain", destination: StressTrackingView().toolbar(.hidden, for: .tabBar))
                            
                            MoreSectionCard(icon: "book.fill", iconColor: .purple, title: "Journal", subtitle: "Capture your thoughts", destination: JournalListView())
                            
                            MoreSectionCard(icon: "waveform.path.ecg", iconColor: .orange, title: "Measurements", subtitle: "Monitor your health data", destination: MeasurementsSummaryView().environmentObject(HealthKitManager.shared))
                            
                            MoreSectionCard(icon: "apple.meditate", iconColor: .green, title: "Mindfulness", subtitle: "Practice calm and focus", destination: MindfulnessHomeView().toolbar(.hidden, for: .tabBar))
                            
                            MoreSectionCard(icon: "heart.fill", iconColor: .red, title: "Heart", subtitle: "Take a look at your beats", destination: HeartSummaryView().environmentObject(HealthKitManager.shared))
                            
                            MoreSectionCard(icon: "pills.fill", iconColor: .pink, title: "Medications", subtitle: "Track your medications with ease", destination: MedicationView().environmentObject(HealthKitManager.shared))
                            
                            MoreSectionCard(icon: "gearshape.fill", iconColor: .gray, title: "Settings", subtitle: "Adjust your preferences", destination: SettingsView().environmentObject(HealthKitManager.shared).environmentObject(MeasurementSystemManager()).environmentObject(AppleSignInManager()))
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 100)
                }
            }
            .safeAreaPadding(.top, 8)
        }
    }
}
struct MoreSectionCard<Destination: View>: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource
    let destination: Destination

    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                iconColor.opacity(0.34),
                iconColor.opacity(0.16),
                Color.black.opacity(0.64)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) { // ✅ 16 → 12 daha sıkı

                // İkon Kutusu
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconColor.opacity(0.25))

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold)) // ✅ 20 → 18
                        .foregroundColor(iconColor)
                }
                .frame(width: 42, height: 42) // ✅ 48 → 42

                VStack(alignment: .leading, spacing: 1) { // ✅ 2 → 1
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded)) // ✅ 17 → 16
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded)) // ✅ 12 → 11
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold)) // ✅ 12 → 11
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 14) // ✅ 16 → 14
            .padding(.vertical, 10)   // ✅ 14 → 10

            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(cardGradient)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.18))

                    Circle()
                        .fill(iconColor.opacity(0.22))
                        .frame(width: 130, height: 130)
                        .blur(radius: 24)
                        .offset(x: -70, y: -34)
                }
            )
            .cornerRadius(18) // ✅ 20 → 18

            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(iconColor.opacity(0.36), lineWidth: 1)
            )
            .shadow(color: iconColor.opacity(0.15),
                    radius: 8, x: 0, y: 4) // ✅ biraz daha soft
        }
        .buttonStyle(PlainButtonStyle())
    }
}

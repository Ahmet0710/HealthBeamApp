import SwiftUI

struct AchievementShareView: View {
    let achievement: Achievement
    
    // SADECE PAYLAŞIM İÇİN ÖZEL "DEEP DARK" RENKLER
    var premiumColor: Color {
        switch achievement.category {
        case .workouts:
            return Color(red: 0.9, green: 0.05, blue: 0.1) // Kan Kırmızısı
        case .nutrition:
            return Color(red: 0.0, green: 0.7, blue: 0.2) // Neon Zümrüt
        case .sleep:
            return Color(red: 0.3, green: 0.3, blue: 1.0) // Elektrik İndigo
        case .habits:
            return Color(red: 0.0, green: 0.5, blue: 1.0) // Derin Okyanus
        case .journaling:
            return Color(red: 0.7, green: 0.0, blue: 0.9) // Ultra Viyole
        case .breathing:
            return Color(red: 0.0, green: 0.8, blue: 0.9) // Parlak Turkuaz
        }
    }
    
    var body: some View {
        ZStack {
            // 1. ARKA PLAN: Zifiri Karanlık (Pitch Black)
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [
                    premiumColor.opacity(0.15), // Çok hafif arka plan ışığı
                    Color.black
                ]),
                center: .center,
                startRadius: 10,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            // Arka plan parıltıları (Çok silik)
            Image(systemName: "sparkles")
                .font(.system(size: 400))
                .foregroundColor(premiumColor.opacity(0.03))
                .rotationEffect(.degrees(-20))
                .offset(x: 100, y: -50)
            
            VStack(spacing: 30) {
                // ÜST BAŞLIK
                HStack(spacing: 8) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title2)
                    Text("HealthBeamApp")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 40)
                
                Spacer()
                
                // 2. "SOLID DARK" KART (BEYAZ IŞIK SİLİNDİ)
                ZStack {
                    // A. Zemin (Simsiyah Katman + Renk)
                    RoundedRectangle(cornerRadius: 35, style: .continuous)
                        .fill(Color.black) // Önce siyahla doldur (Şeffaflığı öldür)
                        .overlay(
                            // Üzerine koyu ama canlı gradient
                            LinearGradient(
                                colors: [
                                    premiumColor.opacity(0.6), // Üst: Rengin koyu hali (Biraz artırdım)
                                    premiumColor.opacity(0.05) // Alt: Neredeyse siyah
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                        // Dışa vuran güçlü neon ışık
                        .shadow(color: premiumColor.opacity(0.6), radius: 60, x: 0, y: 0)
                    
                    // B. Kalın ve Parlak Çerçeve (Rengi patlatan detay)
                    RoundedRectangle(cornerRadius: 35, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    premiumColor,          // Köşede SAF RENK (Çok parlak)
                                    premiumColor.opacity(0.5),
                                    Color.black            // Alt taraf sönüyor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5 // Çizgiyi biraz daha belirginleştirdim
                        )
                    
                    // C. İkon
                    Image(systemName: achievement.icon)
                        .font(.system(size: 110, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        // İkonun arkasına kendi renginden güçlü gölge (Glow)
                        .shadow(color: premiumColor.opacity(0.9), radius: 25, x: 0, y: 0)
                        
                    // NOT: Beyazlık veren "Sheen" Rectangle katmanı buradan silindi.
                }
                .frame(width: 280, height: 360)
                
                // 3. ALT METİNLER
                VStack(spacing: 12) {
                    Text("ACHIEVEMENT UNLOCKED")
                        .font(.system(size: 14, weight: .black))
                        .tracking(4)
                        .foregroundColor(premiumColor) // Neon yazı
                        .shadow(color: premiumColor, radius: 10) // Yazı parlasın
                    
                    Text(achievement.localizedTitle)
                        .font(.system(size: 36, weight: .heavy, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 5)
                }
                .padding(.bottom, 60)
                
                Spacer()
            }
            .padding()
        }
        .frame(width: 450, height: 700) // Instagram Story boyutu
    }
}

import SwiftUI

struct AchievementCardViews: View {
    @State private var isShowing = false
    let achievement: Achievement
    
    // Kartın ne kadar yuvarlak olacağı
    private let cornerRadius: CGFloat = 24.0
    
    var body: some View {
        ZStack {
            // 1. DIŞ GLOW (Sadece kazanılanlar parlasın)
            if !achievement.isLocked {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(achievement.color)
                    .blur(radius: 20) // Arkaya yayılan neon ışık
                    .opacity(0.4) // Parlaklık şiddeti
                    .offset(y: 5)
            }
            
            // 2. KARTIN KENDİSİ (SOLID DARK)
            ZStack {
                // A. Zemin: Simsiyah + Renkli Gradyan
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black) // Şeffaflık bitti, tam siyah.
                    .overlay(
                        LinearGradient(
                            colors: [
                                achievement.isLocked ? .white.opacity(0.05) : achievement.color.opacity(0.5), // Üst: Renkli
                                achievement.isLocked ? .black : achievement.color.opacity(0.05) // Alt: Siyah
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                
                // B. Çerçeve: Neon ve Parlak
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                achievement.isLocked ? .white.opacity(0.1) : achievement.color, // Köşe Parlak
                                achievement.isLocked ? .white.opacity(0.05) : achievement.color.opacity(0.3),
                                Color.black // Alt taraf sönük
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2 // Çerçeveyi belirginleştirdik
                    )
                
                // C. İçerik
                VStack(spacing: 0) {
                    // İkon Alanı
                    ZStack {
                        // Kilitli değilse arkaya ikon renginde glow
                        if !achievement.isLocked {
                            Image(systemName: achievement.icon)
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(achievement.color)
                                .blur(radius: 10)
                                .opacity(0.7)
                        }
                        
                        // İkonun kendisi
                        if achievement.isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.3))
                        } else {
                            Image(systemName: achievement.icon)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: achievement.color.opacity(0.8), radius: 8, y: 0)
                        }
                    }
                    .frame(height: 60)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Metinler
                    VStack(spacing: 6) {
                        Text(achievement.localizedTitle)
                            .font(.system(size: 15, weight: .bold, design: .default)) // Daha ciddi font
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .shadow(color: .black, radius: 2)
                        
                        if achievement.isLocked {
                            // Kilitliyse İlerleme Çubuğu veya LOCKED yazısı
                            if achievement.progress > 0 {
                                VStack(spacing: 4) {
                                    // İlerleme Çubuğu (Bar)
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color.white.opacity(0.1))
                                            Capsule().fill(achievement.color).frame(width: geo.size.width * achievement.progress)
                                        }
                                    }
                                    .frame(height: 4)
                                    
                                    Text("\(Int(achievement.progress * 100))%")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 6)
                            } else {
                                Text("LOCKED")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(.white.opacity(0.2))
                                    .padding(.bottom, 6)
                            }
                        } else {
                            // Kilit Açıksa "EARNED"
                            Text("EARNED")
                                .font(.system(size: 10, weight: .black))
                                .tracking(2)
                                .foregroundColor(achievement.color) // Neon yazı
                                .shadow(color: achievement.color.opacity(0.8), radius: 5)
                                .padding(.bottom, 6)
                        }
                    }
                    .padding(.bottom, 12)
                    .padding(.horizontal, 4)
                }
            }
        }
        .frame(height: 170) // Kart yüksekliği
        .scaleEffect(isShowing ? 1.0 : 0.9)
        .opacity(isShowing ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { isShowing = true }
        }
    }
}

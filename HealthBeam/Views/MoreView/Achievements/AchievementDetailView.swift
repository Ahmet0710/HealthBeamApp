import SwiftUI
import UIKit

struct AchievementDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    let achievement: Achievement
    
    @State private var sharedImage: UIImage?
    @State private var isSharing = false
    var premiumColor: Color {
        switch achievement.category {
        case .workouts: return Color(red: 0.9, green: 0.05, blue: 0.1)
        case .nutrition: return Color(red: 0.0, green: 0.7, blue: 0.2)
        case .sleep: return Color(red: 0.3, green: 0.3, blue: 1.0)
        case .habits: return Color(red: 0.0, green: 0.5, blue: 1.0)
        case .journaling: return Color(red: 0.7, green: 0.0, blue: 0.9)
        case .breathing: return Color(red: 0.0, green: 0.8, blue: 0.9)
        }
    }
    
    @MainActor
    func render(scale: CGFloat) -> UIImage? {
        let renderer = ImageRenderer(content: AchievementShareView(achievement: achievement))
        renderer.scale = scale
        return renderer.uiImage
    }
    
    var body: some View {
        ZStack {
            // 1. ARKA PLAN: Zifiri Karanlık
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [
                    premiumColor.opacity(0.2), // Merkezde hafif bir renk halesi
                    Color.black
                ]),
                center: .center,
                startRadius: 5,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // KAPAT BUTONU
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // 2. "SOLID DARK" ANA KART (Animasyonsuz, Net Duruş)
                ZStack {
                    // A. Zemin (Simsiyah + Renkli Gradyan)
                    RoundedRectangle(cornerRadius: 35, style: .continuous)
                        .fill(Color.black) // Şeffaflık yok, tam siyah
                        .overlay(
                            LinearGradient(
                                colors: [
                                    premiumColor.opacity(0.6), // Üst: Koyu renk
                                    premiumColor.opacity(0.05) // Alt: Siyah
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                        // Arkadan vuran güçlü neon ışık (Glow)
                        .shadow(color: premiumColor.opacity(0.6), radius: 60, x: 0, y: 0)
                    
                    // B. Kalın ve Parlak Çerçeve
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
                            lineWidth: 2.5
                        )
                    
                    // C. İkon
                    Image(systemName: achievement.icon)
                        .font(.system(size: 100, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: premiumColor.opacity(0.9), radius: 25, x: 0, y: 0)
                    
                    // Kilitli İkon (Eğer kilitliyse)
                    if achievement.isLocked {
                        ZStack {
                            Color.black.opacity(0.6) // İkonu biraz karart
                            Image(systemName: "lock.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.8))
                                .shadow(color: .black, radius: 5)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                    }
                }
                .frame(width: 260, height: 340)
                
                // 3. METİNLER
                VStack(spacing: 12) {
                    if !achievement.isLocked {
                        Text("UNLOCKED")
                            .font(.system(size: 14, weight: .black))
                            .tracking(4)
                            .foregroundColor(premiumColor) // Neon yazı
                            .shadow(color: premiumColor.opacity(0.8), radius: 10)
                    } else {
                        Text("LOCKED")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(4)
                            .foregroundColor(.gray)
                            .opacity(0.6)
                    }
                    
                    Text(achievement.localizedTitle)
                        .font(.system(size: 32, weight: .heavy, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 5)
                    
                    Text(achievement.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                    
                    // İlerleme Barı (Sadece kilitli ve ilerleme varsa)
                    if achievement.isLocked && achievement.progress > 0 {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Progress").font(.caption).foregroundColor(.white.opacity(0.5))
                                Spacer()
                                Text("\(Int(achievement.progress * 100))%").font(.caption.monospacedDigit()).foregroundColor(.white.opacity(0.5))
                            }
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.1)).frame(height: 6)
                                Capsule().fill(premiumColor).frame(width: 200 * achievement.progress, height: 6)
                                    .shadow(color: premiumColor, radius: 5) // Bar da parlasın
                            }
                        }
                        .frame(width: 200)
                        .padding(.top, 10)
                    }
                }
                .padding(.top, 40)
                
                // 4. AKSİYON BUTONU (Güçlü ve Renkli)
                Button(action: {
                    if !achievement.isLocked, let image = render(scale: displayScale) {
                        self.sharedImage = image
                        self.isSharing = true
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                        Text("Share Achievement")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        premiumColor.opacity(0.9), // Üst taraf güçlü renk
                                        premiumColor.opacity(0.6)  // Alt taraf hafif
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: premiumColor.opacity(0.4), radius: 20, y: 10)
                }
                .padding(.horizontal, 40)
                .padding(.top, 30)
                .padding(.bottom, 50)
                .opacity(achievement.isLocked ? 0.0 : 1.0)
                
                Spacer(minLength: 0)
            }
        }
        .sheet(isPresented: $isSharing) {
            if let image = sharedImage {
                ShareSheet(activityItems: [image, String(localized: "I unlocked \(achievement.localizedTitle) in HealthBeam.")])
            }
        }
    }
}

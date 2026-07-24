//
//  MiniPlayerView.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/2/26.
//


import SwiftUI

struct MiniPlayerView: View {
    // AudioManager'a erişim (Ana sayfadan gelecek)
    @EnvironmentObject var audioManager: AudioManager

    // Şu an çalan meditasyonu bulur
    var currentMeditation: Meditation? {
        return allMeditations.first(where: { $0.id == audioManager.currentMeditationID })
    }

    var body: some View {
        VStack(spacing: 10) {
            // 1. Şarkı İsmi ve Kategori
            if let meditation = currentMeditation {
                VStack(spacing: 2) {
                    Text(meditation.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(meditation.categoryName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("No meditation selected ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // 2. İlerleme Çubuğu (Slider)
            Slider(value: Binding(get: {
                audioManager.playbackProgress
            }, set: { newValue in
                audioManager.seek(by: newValue)
            }), in: 0...(audioManager.totalDuration > 0 ? audioManager.totalDuration : 1))
            .accentColor(.blue)

            // 3. Süreler (00:00)
            HStack {
                Text(formatTime(audioManager.playbackProgress))
                    .font(.caption2)
                    .monospacedDigit() // Rakamlar titremesin diye sabit genişlik
                
                Spacer()
                
                if audioManager.isLoading {
                    ProgressView().scaleEffect(0.7)
                } else {
                    Text(formatTime(audioManager.totalDuration))
                        .font(.caption2)
                        .monospacedDigit()
                }
            }
            
            // 4. Play/Pause Butonu
            Button(action: {
                audioManager.playPause()
            }) {
                Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.blue)
                    .shadow(radius: 2)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground)) // Arka plan rengi
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding()
    }

    // "Empty string" hatasını ve NaN sorununu çözen fonksiyon
    func formatTime(_ time: Double) -> String {
        if time.isNaN || time.isInfinite { return "00:00" }
        let seconds = Int(time)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

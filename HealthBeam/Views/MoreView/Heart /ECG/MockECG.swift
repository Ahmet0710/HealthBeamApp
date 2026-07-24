import Foundation
import HealthKit

struct mockECGs {
    
    // MARK: - Dalga Formu Üretici (Grafik İçin)
    
    /// Belirtilen süre ve nabız hızına göre sahte bir EKG dalga formu (Sinüs Ritmi) üretir.
    static func generateSinusRhythmWaveform(duration: Double, heartRate: Double) -> [ECGPoint] {
        var points: [ECGPoint] = []
        let frequency = 512.0
        let totalSamples = Int(duration * frequency)
        let beatDuration = 60.0 / heartRate
        
        for i in 0..<totalSamples {
            let t = Double(i) / frequency
            let phase = t.truncatingRemainder(dividingBy: beatDuration)
            let p = phase / beatDuration
            var voltage = 0.0
            
            // İsoelektrik Hat
            voltage += Double.random(in: -0.02...0.02)
            
            // P Dalgası
            if p > 0.10 && p < 0.20 {
                voltage += 0.15 * sin((p - 0.10) / 0.10 * .pi)
            }
            
            // QRS Kompleksi
            if p > 0.35 && p < 0.45 {
                if p < 0.38 { voltage -= 0.15 * ((p - 0.35) / 0.03) }
                else if p < 0.42 { voltage += 1.6 }
                else { voltage -= 0.35 }
            } else if p > 0.45 && p < 0.47 {
                voltage += (0.47 - p) * 2.0
            }
            
            // T Dalgası
            if p > 0.60 && p < 0.80 {
                voltage += 0.25 * sin((p - 0.60) / 0.20 * .pi)
            }
            
            points.append(ECGPoint(time: t, voltage: voltage))
        }
        return points
    }
    
    // MARK: - Örnek Liste Verisi (HeartSummaryView İçin)
    // Hatanın sebebi bu kısmın eksik olmasıydı.
    
    static var sampleEntries: [ECGEntry] {
        return [
            ECGEntry(
                id: UUID(),
                date: Date(),
                classification: .sinusRhythm,
                averageHeartRate: 72,
                sample: nil // Demo modunda sample nil olabilir
            ),
            ECGEntry(
                id: UUID(),
                date: Date().addingTimeInterval(-3600), // 1 saat önce
                classification: .inconclusiveHighHeartRate,
                averageHeartRate: 110,
                sample: nil
            ),
            ECGEntry(
                id: UUID(),
                date: Date().addingTimeInterval(-86400), // Dün
                classification: .atrialFibrillation,
                averageHeartRate: 88,
                sample: nil
            ),
            ECGEntry(
                id: UUID(),
                date: Date().addingTimeInterval(-172800), // 2 gün önce
                classification: .sinusRhythm,
                averageHeartRate: 65,
                sample: nil
            )
        ]
    }
}

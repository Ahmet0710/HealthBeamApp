//
//  MockHeart.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/3/26.
//


//
//  MockHeart.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/3/26.
//

import Foundation

struct MockHeart {
    
    /// Demo modu için son 6 aylık detaylı kalp verileri
    static var sampleHeartEntries: [HeartEntry] {
        var entries: [HeartEntry] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Geriye dönük 180 gün (6 ay)
        for i in 0..<180 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            
            // 1. Kalp Atış Hızı (Heart Rate) - Günde 4-5 ölçüm
            // Genelde 60-100 arası, bazen spor yapınca artar
            let measurementsCount = Int.random(in: 3...6)
            for _ in 0..<measurementsCount {
                let hour = Int.random(in: 8...22)
                let minute = Int.random(in: 0...59)
                if let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                    // Rastgele bir "aktivite" faktörü
                    let isActive = Double.random(in: 0...1) > 0.8
                    let bpm = isActive ? Double.random(in: 90...130) : Double.random(in: 60...90)
                    entries.append(HeartEntry(metric: .heartRate, value: bpm, date: time))
                }
            }
            
            // 2. Dinlenme Kalp Hızı (Resting Heart Rate) - Günde 1 kez (Sabah)
            // 55-65 arası stabil
            if let restingTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date) {
                // Hafif dalgalanma
                let restingBpm = 60.0 + Double.random(in: -3...3)
                entries.append(HeartEntry(metric: .restingHeartRate, value: restingBpm, date: restingTime))
            }
            
            // 3. Kalp Hızı Değişkenliği (HRV) - Günde 1 kez
            // 30-60 ms arası
            if let hrvTime = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: date) {
                let hrv = 45.0 + Double.random(in: -10...15)
                entries.append(HeartEntry(metric: .heartRateVariability, value: hrv, date: hrvTime))
            }
            
            // 4. Yürüyüş Ortalama Nabzı (Walking Heart Rate) - Her gün olmayabilir
            if i % 2 == 0 {
                if let walkTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date) {
                    let walkBpm = 95.0 + Double.random(in: -5...10)
                    entries.append(HeartEntry(metric: .walkingHeartRate, value: walkBpm, date: walkTime))
                }
            }
            
            // 5. Kardiyo Fitness (VO2 Max) - Ayda 1-2 kez
            if i % 15 == 0 {
                if let fitnessTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) {
                    // Yavaşça artan bir kondisyon (42 -> 45)
                    let progress = Double(180 - i) / 180.0
                    let vo2 = 42.0 + (3.0 * progress) + Double.random(in: -0.5...0.5)
                    entries.append(HeartEntry(metric: .cardioFitness, value: vo2, date: fitnessTime))
                }
            }
            
            // 6. Kardiyo İyileşmesi (Cardio Recovery) - Haftada 1-2 kez
            if i % 5 == 0 {
                if let recoveryTime = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: date) {
                    // Antrenman sonrası düşüş (bpm)
                    let recovery = 25.0 + Double.random(in: -5...5)
                    entries.append(HeartEntry(metric: .cardioRecovery, value: recovery, date: recoveryTime))
                }
            }
        }
        
        return entries
    }
}


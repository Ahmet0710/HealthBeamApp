//
//  MockMeasurements.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/3/26.
//

import Foundation

struct MockMeasurements {
    
    /// Demo modu için TÜM kategorileri içeren genişletilmiş ölçüm verileri
    static var sampleMeasurements: [MeasurementEntry] {
        var entries: [MeasurementEntry] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Simülasyon Sabitleri
        let heightMeters = 1.80 // Boy 1.80m sabit varsayalım
        
        // Geriye dönük 180 gün (6 ay) için döngü
        for i in 0..<180 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            
            // Progress: 0.0 (180 gün önce) -> 1.0 (Bugün)
            let progress = Double(180 - i) / 180.0
            
            // --- GRUP 1: Vücut Kompozisyonu (Kilo, BMI, Yağ, Kas, Bel) ---
            
            // Ağırlık (Weight): 88kg'dan 80kg'a düşen bir trend
            // Her 2-3 günde bir ölçüm yapılmış gibi
            if i % 3 == 0 {
                let baseWeight = 88.0 - (8.0 * progress) // 88 -> 80
                let randomFlux = Double.random(in: -0.6...0.6) // Günlük dalgalanma
                let weight = baseWeight + randomFlux
                
                entries.append(MeasurementEntry(type: .weight, value: weight, date: date))
                
                // Body Mass Index (BMI) Hesaplama: Kilo / Boy^2
                // Ağırlık ölçüldüğü an BMI da otomatik hesaplanır
                let bmi = weight / (heightMeters * heightMeters)
                entries.append(MeasurementEntry(type: .bodyMassIndex, value: bmi, date: date))
            }
            
            // Vücut Yağ Oranı (Body Fat %): %24 -> %19
            // Haftada 1 ölçüm
            if i % 7 == 0 {
                let baseFat = 24.0 - (5.0 * progress)
                let fat = baseFat + Double.random(in: -0.3...0.3)
                entries.append(MeasurementEntry(type: .bodyFatPercentage, value: fat, date: date))
                
                // Kas Kütlesi (Lean Body Mass)
                // Mantık: Ağırlık * (1 - Yağ Oranı)
                // O günkü tahmini kiloyu alalım
                let currentWeight = 88.0 - (8.0 * progress)
                let leanMass = currentWeight * (1.0 - (fat / 100.0))
                entries.append(MeasurementEntry(type: .leanBodyMass, value: leanMass, date: date))
            }
            
            // Bel Çevresi (Waist Circumference): 98cm -> 90cm
            // 2 haftada bir ölçüm
            if i % 14 == 0 {
                let waist = 98.0 - (8.0 * progress)
                entries.append(MeasurementEntry(type: .waistCircumference, value: waist, date: date))
            }
            
            // --- GRUP 2: Sıcaklık Ölçümleri (Body, Basal, Wrist) ---
            
            // Vücut Sıcaklığı (Body Temperature) - Son 14 gün
            // Rastgele hasta olma veya normal dalgalanma
            if i < 14 {
                // Günde bazen 1, bazen 2 ölçüm
                let measurementsToday = Int.random(in: 1...2)
                for _ in 0..<measurementsToday {
                    let hour = Int.random(in: 8...22)
                    if let tempDate = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) {
                        // 36.5 - 37.1 arası normal değerler
                        let temp = Double.random(in: 36.5...37.1)
                        entries.append(MeasurementEntry(type: .bodyTemperature, value: temp, date: tempDate))
                    }
                }
            }
            
            // Bazal Vücut Sıcaklığı (Basal Body Temperature) - Son 30 gün
            // Sabah uyanınca (06:30 civarı) ölçülür, daha stabil ve düşüktür.
            if i < 30 {
                if let basalDate = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: date) {
                    // 36.1 - 36.5 arası
                    let basalTemp = Double.random(in: 36.1...36.5)
                    entries.append(MeasurementEntry(type: .basalBodyTemperature, value: basalTemp, date: basalDate))
                }
            }
            
            // Bilek Sıcaklığı (Wrist Temperature) - Son 7 gün (Apple Watch verisi gibi)
            // Gece uykusunda (03:00 - 05:00) ölçülür.
            if i < 7 {
                if let wristDate = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: date) {
                    // Genelde vücuttan biraz daha değişkendir
                    let wristTemp = Double.random(in: 35.5...36.8)
                    entries.append(MeasurementEntry(type: .wristTemperature, value: wristTemp, date: wristDate))
                }
            }
        }
        
        // --- GRUP 3: Boy (Height) ---
        // Boy değişmez ama grafikte nokta görünmesi için ayda bir veri atalım
        for i in stride(from: 0, to: 180, by: 30) {
            if let hDate = calendar.date(byAdding: .day, value: -i, to: today) {
                entries.append(MeasurementEntry(type: .height, value: heightMeters * 100, date: hDate)) // cm cinsinden
            }
        }
        // Bir de bugün için ekleyelim
        entries.append(MeasurementEntry(type: .height, value: heightMeters * 100, date: today))
        
        return entries
    }
}

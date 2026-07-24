//
//  MockSleep.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/3/26.
//

import Foundation
import HealthKit

struct MockSleep {
    
    /// Demo modu için son 1 yıllık TUTARLI uyku verisi üretir
    static func generateMockHistory() -> [DailySleepAnalysis] {
        var analyses: [DailySleepAnalysis] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Geriye dönük 365 gün veri üret
        for i in 0..<365 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            
            // Hafta sonu daha çok uyusun
            let isWeekend = calendar.isDateInWeekend(date)
            let wakeHour = Int.random(in: isWeekend ? 8...10 : 6...8)
            let wakeMinute = Int.random(in: 0...59)
            
            guard let wakeTime = calendar.date(bySettingHour: wakeHour, minute: wakeMinute, second: 0, of: date) else { continue }
            
            // 6 ile 9.5 saat arası uyku
            let sleepDurationHours = Double.random(in: 5.5...9.5)
            let sleepStartTime = wakeTime.addingTimeInterval(-sleepDurationHours * 3600)
            
            // Parçacıkları oluştur (Awakening Count burada oluşacak)
            let periods = generatePeriods(start: sleepStartTime, end: wakeTime)
            
            // DailySleepAnalysis, bu periodlara bakarak Puanı ve Süreleri kendisi hesaplar
            let analysis = DailySleepAnalysis(
                date: date,
                stagePeriods: periods
            )
            
            analyses.append(analysis)
        }
        
        // Tarihe göre sırala (En yeni en sonda olsun, ViewModel tersini yapıyorsa orada düzelir)
        return analyses.sorted(by: { $0.date < $1.date })
    }
    
    /// Uyku evrelerini ve UYANIKLIKLARI oluşturur
    private static func generatePeriods(start: Date, end: Date) -> [SleepStagePeriod] {
        var periods: [SleepStagePeriod] = []
        var currentTime = start
        
        // 1. Yatağa giriş (İlk 15-30 dk uyanık/yatakta)
        let timeToFallAsleep = Double.random(in: 10...30) * 60
        let sleepStartActual = start.addingTimeInterval(timeToFallAsleep)
        periods.append(SleepStagePeriod(type: .inBed, startDate: start, endDate: sleepStartActual))
        currentTime = sleepStartActual
        
        // Döngüsel evreler
        while currentTime < end {
            let remainingTime = end.timeIntervalSince(currentTime)
            
            // Son 20 dk kaldıysa hafif uykuyla bitir
            if remainingTime < 20 * 60 {
                periods.append(SleepStagePeriod(type: .light, startDate: currentTime, endDate: end))
                break
            }
            
            // Bazen gece uyanması ekle (%15 ihtimal)
            // Bu sayede "Awakening Count" verisi oluşacak
            if Double.random(in: 0...1) < 0.15 {
                let awakeDuration = Double.random(in: 2...10) * 60 // 2-10 dk uyanıklık
                let awakeEnd = min(currentTime.addingTimeInterval(awakeDuration), end)
                periods.append(SleepStagePeriod(type: .awake, startDate: currentTime, endDate: awakeEnd))
                currentTime = awakeEnd
                continue
            }
            
            // Normal Uyku Evresi Ekle
            // Hafif, Derin veya REM
            let stageDuration = Double.random(in: 20...60) * 60
            let stageEnd = min(currentTime.addingTimeInterval(stageDuration), end)
            
            let roll = Int.random(in: 0...100)
            let type: SleepStage
            
            // Kabaca evre dağılımı
            if roll < 50 { type = .light }
            else if roll < 75 { type = .deep }
            else { type = .rem }
            
            periods.append(SleepStagePeriod(type: type, startDate: currentTime, endDate: stageEnd))
            currentTime = stageEnd
        }
        
        return periods
    }
    
    /// Sadece VITAL veriler (Nabız, HRV, Solunum) için rastgele veri üretir.
    /// Uyku süreleri için YUKARIDAKİ `generateMockHistory` kullanılır.
    static func generateMockVitalData(for metric: HealthDataType, days: Int = 365) -> [MetricDataPoint] {
        var points: [MetricDataPoint] = []
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            
            var value: Double = 0
            switch metric {
            case .heartRateAverage: value = Double.random(in: 55...75)
            case .heartRateLowest: value = Double.random(in: 45...58)
            case .hrv: value = Double.random(in: 35...85)
            case .respiratoryRate: value = Double.random(in: 13...16.5)
            default: continue // Diğerleri (Sleep Duration vs) buradan gelmeyecek
            }
            
            points.append(MetricDataPoint(date: date, value: value))
        }
        return points
    }
}

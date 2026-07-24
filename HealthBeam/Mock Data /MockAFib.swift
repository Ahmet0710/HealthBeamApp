import Foundation

struct MockAFib {
    
    /// Demo modu için son 6 aylık (24 hafta) AFib Yükü verisi üretir.
    static var sampleEntries: [AFibWeeklyEntry] {
        var entries: [AFibWeeklyEntry] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Geriye dönük 24 hafta (6 ay) veri üret
        for i in 0..<24 {
            // Her döngüde 1 hafta geriye git
            guard let date = calendar.date(byAdding: .weekOfYear, value: -i, to: today) else { continue }
            
            // SENARYO:
            // Kullanıcının AFib yükü genelde düşüktür (%2 ve altı).
            // Ancak bazı haftalar stres veya yorgunlukla artış (%4-6) gösterebilir.
            
            let burden: Double
            let chance = Double.random(in: 0...100)
            
            if chance < 40 {
                // %40 ihtimalle o hafta hiç AFib yok (%0)
                burden = 0.0
            } else if chance < 85 {
                // %45 ihtimalle çok düşük (%2 ve altı)
                burden = Double.random(in: 0.005...0.02)
            } else {
                // %15 ihtimalle biraz yüksek (%2 - %6 arası)
                burden = Double.random(in: 0.02...0.06)
            }
            
            // Haftanın başlangıç ve bitiş tarihlerini hesapla
            let weekStart: Date
            if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start {
                weekStart = startOfWeek
            } else {
                // Yedek: günü baz al
                weekStart = calendar.startOfDay(for: date)
            }
            // Haftanın bitişi: başlangıç + 6 gün, gün sonu
            let weekEndBase = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let weekEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: weekEndBase) ?? weekEndBase

            let entry = AFibWeeklyEntry(
                weekStart: weekStart,
                weekEnd: weekEnd,
                percentage: burden
            )
            
            entries.append(entry)
        }
        
        // Tarihe göre sırala (Eskiden yeniye)
        return entries.sorted(by: { $0.weekStart < $1.weekStart })
    }
}

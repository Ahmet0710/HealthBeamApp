//
//  MockMedicationData.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/4/26.
//


import Foundation
import CoreData
import SwiftUI

struct MockMedicationData {
    static let shared = MockMedicationData()
    private let context: NSManagedObjectContext

    init() {
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = PersistenceController.shared.container.viewContext
        childContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        context = childContext
    }

    /// Belirtilen tarih için örnek ilaçlar üretir
    func getMockMedications(for date: Date) -> [Medication] {
        context.reset()
        var meds: [Medication] = []
        let calendar = Calendar.current
        
        // ---------------------------------------------------------
        // 1. İLAÇ: Amoxicillin (Günde 2 Defa - Sabah 09:00 ve Akşam 21:00)
        // ---------------------------------------------------------
        let times1 = [9, 21] // Saatler
        
        for hour in times1 {
            let med = Medication(context: context)
            med.id = UUID()
            med.medicineID = UUID() // Gruplamak için
            med.name = "Amoxicillin"
            med.dosage = "500 mg - Capsule"
            med.totalStock = 20
            med.remainingStock = 14
            med.colorHex = "#4A90E2" // Mavi tonu
            
            // Sabahkini "Alınmış" (Taken) yapalım, akşamki "Alınmamış" kalsın
            med.isTaken = (hour == 9) 
            
            // Tarihi ayarla
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = hour
            components.minute = 0
            med.reminderTime = calendar.date(from: components)
            
            meds.append(med)
        }
        
        // ---------------------------------------------------------
        // 2. İLAÇ: Vitamin D (Günde 1 Defa - Öğlen 13:00)
        // ---------------------------------------------------------
        let med2 = Medication(context: context)
        med2.id = UUID()
        med2.medicineID = UUID()
        med2.name = "Vitamin D"
        med2.dosage = "1000 IU - Tablet"
        med2.totalStock = 60
        med2.remainingStock = 59
        med2.colorHex = "#F5A623" // Turuncu
        med2.isTaken = false // Alınmadı
        
        var components2 = calendar.dateComponents([.year, .month, .day], from: date)
        components2.hour = 13
        components2.minute = 0
        med2.reminderTime = calendar.date(from: components2)
        meds.append(med2)
        
        // Listeyi saate göre sırala
        return meds.sorted { ($0.reminderTime ?? Date()) < ($1.reminderTime ?? Date()) }
    }
}

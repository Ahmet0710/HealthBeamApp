//
//  MockJournal.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/3/26.
//


//
//  MockJournal.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/3/26.
//

import Foundation
import SwiftData
import CoreLocation

struct MockJournal {
    /// Demo modu için zenginleştirilmiş günlük girişleri
    static var sampleEntries: [JournalEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        // --- GİRİŞ 1: BUGÜN SABAH (Morning Reflection) ---
        let date1 = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: now)!
        let entry1 = JournalEntry(
            id: UUID(),
            date: date1,
            title: "Morning Reflection",
            mood: "happy", // Asset ismine göre değişebilir, genelde "happy" veya emoji
            isBookmarked: true
        )
        
        let block1 = ContentBlock(text: "Started the day with a 5km run. Feeling energized and ready to tackle the project deadlines today. The weather is absolutely perfect.")
        block1.journalEntry = entry1
        entry1.contentBlocks = [block1]
        
        // --- GİRİŞ 2: BUGÜN ÖĞLEDEN SONRA (Coffee Break & Location) ---
        let date2 = calendar.date(bySettingHour: 14, minute: 15, second: 0, of: now)!
        let entry2 = JournalEntry(
            id: UUID(),
            date: date2,
            title: "Coffee Break",
            mood: "relaxed",
            isBookmarked: false
        )
        
        let block2Text = ContentBlock(text: "Found a quiet spot at the new coffee shop. The latte art is amazing!")
        let block2Loc = ContentBlock(name: "Central Park Cafe", latitude: 40.785091, longitude: -73.968285)
        
        block2Text.journalEntry = entry2
        block2Loc.journalEntry = entry2
        entry2.contentBlocks = [block2Text, block2Loc]
        
        // --- GİRİŞ 3: DÜN AKŞAM (Gratitude) ---
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let date3 = calendar.date(bySettingHour: 21, minute: 45, second: 0, of: yesterday)!
        let entry3 = JournalEntry(
            id: UUID(),
            date: date3,
            title: "Daily Gratitude",
            mood: "grateful",
            isBookmarked: true
        )
        
        let block3 = ContentBlock(text: "Today I am grateful for:\n1. My supportive family\n2. Finishing the book I started\n3. A delicious dinner")
        block3.journalEntry = entry3
        entry3.contentBlocks = [block3]
        
        // --- GİRİŞ 4: 2 GÜN ÖNCE (Thoughts) ---
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!
        let date4 = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: twoDaysAgo)!
        let entry4 = JournalEntry(
            id: UUID(),
            date: date4,
            title: "Late Night Thoughts",
            mood: "thoughtful",
            isBookmarked: false
        )
        
        let block4 = ContentBlock(text: "Sometimes it's hard to disconnect from work. Need to focus more on mindfulness before bed.")
        block4.journalEntry = entry4
        entry4.contentBlocks = [block4]
        
        // --- GİRİŞ 5: 3 GÜN ÖNCE (Weekend Trip) ---
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let date5 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: threeDaysAgo)!
        let entry5 = JournalEntry(
            id: UUID(),
            date: date5,
            title: "Weekend Trip",
            mood: "excited",
            isBookmarked: true
        )
        
        let block5 = ContentBlock(text: "Packing bags for the weekend getaway. Can't wait to see the mountains!")
        block5.journalEntry = entry5
        entry5.contentBlocks = [block5]
        
        return [entry1, entry2, entry3, entry4, entry5]
    }
}

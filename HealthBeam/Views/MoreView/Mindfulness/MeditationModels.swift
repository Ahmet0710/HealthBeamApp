import Foundation
import SwiftUI

// MARK: - Models

struct MainCategory: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    // Artık indirme işlemi tek tek dosyalar üzerinden yapıldığı için
    // buradaki assetPackID sadece kategoriyi gruplamak için referans kalabilir
    // veya ileride "Tümünü İndir" özelliği yaparsan kullanabilirsin.
    let assetPackID: String
}

struct Meditation: Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let durationInMinutes: Int
    let audioFileName: String
    let categoryName: String
    
    // ✅ YENİ: Xcode'daki "On Demand Resource Tag" ile eşleşecek kimlik
    // Her dosya için benzersiz bir etiket oluşturduk.
    let odrTag: String
    
    var duration: TimeInterval {
        TimeInterval(durationInMinutes * 60)
    }

    var achievementTags: Set<MeditationAchievementTag> {
        var tags: Set<MeditationAchievementTag> = []

        switch categoryName {
        case "Inner Peace and Calmness":
            tags.insert(.calmDown)
        case "Energy and Focus":
            tags.insert(.focus)
        case "Relaxing Sleep":
            tags.insert(.beforeSleep)
        default:
            break
        }

        if title == "Breath Awareness" {
            tags.insert(.boxBreathing)
            tags.insert(.postWorkoutRecovery)
        }

        return tags
    }
}

enum MeditationAchievementTag: Hashable {
    case calmDown
    case focus
    case beforeSleep
    case boxBreathing
    case postWorkoutRecovery
}

struct CompletedSession: Identifiable, Codable {
    let id: UUID
    let meditationID: UUID
    let completionDate: Date
    
    init(id: UUID = UUID(), meditationID: UUID, completionDate: Date) {
        self.id = id
        self.meditationID = meditationID
        self.completionDate = completionDate
    }
}

// MARK: - Data

// 1. KATEGORİLER
let mainCategories: [MainCategory] = [
    MainCategory(name: "Relaxing Sleep", imageName: "category_sleep.png", assetPackID: "Meditation"),
    MainCategory(name: "Self-Worth and Love", imageName: "category_selflove.png", assetPackID: "Meditation"),
    MainCategory(name: "Relationships and Connection", imageName: "category_connection.png", assetPackID: "Meditation"),
    MainCategory(name: "Inner Peace and Calmness", imageName: "category_calm.png", assetPackID: "Meditation"),
    MainCategory(name: "Growth and Transformation", imageName: "category_growth.png", assetPackID: "Meditation"),
    MainCategory(name: "Energy and Focus", imageName: "category_focus.png", assetPackID: "Meditation")
]

// 2. MEDİTASYONLAR (Her biri için özel Tag eklendi)
// ⚠️ DİKKAT: Xcode'da dosyalara vereceğin etiketler buradaki 'odrTag' ile AYNI olmalı.

let allMeditations: [Meditation] = [

    // MARK: - Relaxing Sleep
    // Xcode Tags: audio_sleep_01, audio_sleep_02, audio_sleep_03
    Meditation(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
        title: "Quick Sleep Prep",
        description: "Prepare your body for rest.",
        durationInMinutes: 5,
        audioFileName: "5 minutes - Relaxing Sleep",
        categoryName: "Relaxing Sleep",
        odrTag: "audio_sleep_01"
    ),
    Meditation(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        title: "Deep Relaxation",
        description: "Let go of the day's stress.",
        durationInMinutes: 10,
        audioFileName: "10 minutes - Relaxing Sleep ",
        categoryName: "Relaxing Sleep",
        odrTag: "audio_sleep_02"
    ),
    Meditation(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
        title: "Deep Sleep Journey",
        description: "A long journey into deep sleep.",
        durationInMinutes: 20,
        audioFileName: "20 minutes - Relaxing Sleep ",
        categoryName: "Relaxing Sleep",
        odrTag: "audio_sleep_03"
    ),

    // MARK: - Self-Worth and Love
    // Xcode Tags: audio_self_01 ... audio_self_05
    Meditation(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
        title: "Self Acceptance",
        description: "Accept yourself as you are.",
        durationInMinutes: 5,
        audioFileName: "5 minutes - Self Worth and  Love",
        categoryName: "Self-Worth and Love",
        odrTag: "audio_self_01"
    ),
    Meditation(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!,
        title: "Worthy of Love",
        description: "Feel the love within you.",
        durationInMinutes: 7,
        audioFileName: "7 minutes - Self Worth and  Love",
        categoryName: "Self-Worth and Love",
        odrTag: "audio_self_02"
    ),
    Meditation(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000003")!,
        title: "Compassion Break",
        description: "Be kind to yourself.",
        durationInMinutes: 10,
        audioFileName: "10 minutes - Self Worth and  Love",
        categoryName: "Self-Worth and Love",
        odrTag: "audio_self_03"
    ),
    Meditation(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000004")!,
        title: "Inner Strength",
        description: "Connect with your core strength.",
        durationInMinutes: 15,
        audioFileName: "15 minutes - Self Worth and  Love",
        categoryName: "Self-Worth and Love",
        odrTag: "audio_self_04"
    ),
    Meditation(
        id: UUID(uuidString: "20000000-0000-0000-0000-000000000005")!,
        title: "Complete Self-Love",
        description: "Deep dive into self-love.",
        durationInMinutes: 20,
        audioFileName: "20 minutes - Self Worth and  Love",
        categoryName: "Self-Worth and Love",
        odrTag: "audio_self_05"
    ),

    // MARK: - Relationships and Connection
    // Xcode Tags: audio_rel_01 ... audio_rel_05
    Meditation(
        id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
        title: "Quick Connection",
        description: "Connect with your surroundings.",
        durationInMinutes: 5,
        audioFileName: "5 minutes - Relationships and Connections",
        categoryName: "Relationships and Connection",
        odrTag: "audio_rel_01"
    ),
    Meditation(
        id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
        title: "Empathy Builder",
        description: "Understand others better.",
        durationInMinutes: 7,
        audioFileName: "7 minutes - Relationships and Connections",
        categoryName: "Relationships and Connection",
        odrTag: "audio_rel_02"
    ),
    Meditation(
        id: UUID(uuidString: "30000000-0000-0000-0000-000000000003")!,
        title: "Loving Kindness",
        description: "Send love to everyone.",
        durationInMinutes: 10,
        audioFileName: "10 minutes - Relationships and Connections",
        categoryName: "Relationships and Connection",
        odrTag: "audio_rel_03"
    ),
    Meditation(
        id: UUID(uuidString: "30000000-0000-0000-0000-000000000004")!,
        title: "Forgiveness",
        description: "Let go of past hurts.",
        durationInMinutes: 15,
        audioFileName: "15 minutes - Relationships and Connections",
        categoryName: "Relationships and Connection",
        odrTag: "audio_rel_04"
    ),
    Meditation(
        id: UUID(uuidString: "30000000-0000-0000-0000-000000000005")!,
        title: "Deep Bonding",
        description: "Strengthen your relationships.",
        durationInMinutes: 20,
        audioFileName: "20 minutes - Relationships and Connections",
        categoryName: "Relationships and Connection",
        odrTag: "audio_rel_05"
    ),

    // MARK: - Inner Peace and Calmness
    // Xcode Tags: audio_peace_01 ... audio_peace_05
    Meditation(
        id: UUID(uuidString: "40000000-0000-0000-0000-000000000001")!,
        title: "Instant Calm",
        description: "Find peace in 5 minutes.",
        durationInMinutes: 5,
        audioFileName: "5 minutes - Inner peace",
        categoryName: "Inner Peace and Calmness",
        odrTag: "audio_peace_01"
    ),
    Meditation(
        id: UUID(uuidString: "40000000-0000-0000-0000-000000000002")!,
        title: "Serene Mind",
        description: "Clear your thoughts.",
        durationInMinutes: 7,
        audioFileName: "7 minutes - Inner peace",
        categoryName: "Inner Peace and Calmness",
        odrTag: "audio_peace_02"
    ),
    Meditation(
        id: UUID(uuidString: "40000000-0000-0000-0000-000000000003")!,
        title: "Breath Awareness",
        description: "Focus on your breath.",
        durationInMinutes: 10,
        audioFileName: "10 minutes - Inner peace",
        categoryName: "Inner Peace and Calmness",
        odrTag: "audio_peace_03"
    ),
    Meditation(
        id: UUID(uuidString: "40000000-0000-0000-0000-000000000004")!,
        title: "Peaceful Space",
        description: "Go to your happy place.",
        durationInMinutes: 15,
        audioFileName: "15 minutes - Inner peace",
        categoryName: "Inner Peace and Calmness",
        odrTag: "audio_peace_04"
    ),
    Meditation(
        id: UUID(uuidString: "40000000-0000-0000-0000-000000000005")!,
        title: "Deep Tranquility",
        description: "Total relaxation for the mind.",
        durationInMinutes: 20,
        audioFileName: "20 minutes - Inner peace",
        categoryName: "Inner Peace and Calmness",
        odrTag: "audio_peace_05"
    ),

    // MARK: - Growth and Transformation
    // Xcode Tags: audio_growth_01 ... audio_growth_05
    Meditation(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000001")!,
        title: "New Beginning",
        description: "Start fresh right now.",
        durationInMinutes: 4,
        audioFileName: "4 minutes - Growth and Transformation",
        categoryName: "Growth and Transformation",
        odrTag: "audio_growth_01"
    ),
    Meditation(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000002")!,
        title: "Embracing Change",
        description: "Accept changes in life.",
        durationInMinutes: 7,
        audioFileName: "7 minutes - Growth and Transformation",
        categoryName: "Growth and Transformation",
        odrTag: "audio_growth_02"
    ),
    Meditation(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000003")!,
        title: "Setting Intentions",
        description: "Focus on your goals.",
        durationInMinutes: 10,
        audioFileName: "10 minutes - Growth and Transformation",
        categoryName: "Growth and Transformation",
        odrTag: "audio_growth_03"
    ),
    Meditation(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000004")!,
        title: "Resilience",
        description: "Build inner toughness.",
        durationInMinutes: 15,
        audioFileName: "15 minutes - Growth and Transformation",
        categoryName: "Growth and Transformation",
        odrTag: "audio_growth_04"
    ),
    Meditation(
        id: UUID(uuidString: "50000000-0000-0000-0000-000000000005")!,
        title: "Best Version",
        description: "Visualize your best self.",
        durationInMinutes: 20,
        audioFileName: "20 minutes - Growth and Transformation",
        categoryName: "Growth and Transformation",
        odrTag: "audio_growth_05"
    ),

    // MARK: - Energy and Focus
    // Xcode Tags: audio_focus_01 ... audio_focus_05
    Meditation(
        id: UUID(uuidString: "60000000-0000-0000-0000-000000000001")!,
        title: "Morning Boost",
        description: "Wake up your mind.",
        durationInMinutes: 5,
        audioFileName: "5 minutes - Energy and Focus",
        categoryName: "Energy and Focus",
        odrTag: "audio_focus_01"
    ),
    Meditation(
        id: UUID(uuidString: "60000000-0000-0000-0000-000000000002")!,
        title: "Quick Focus",
        description: "Sharpen your attention.",
        durationInMinutes: 7,
        audioFileName: "7 minutes - Energy and Focus",
        categoryName: "Energy and Focus",
        odrTag: "audio_focus_02"
    ),
    Meditation(
        id: UUID(uuidString: "60000000-0000-0000-0000-000000000003")!,
        title: "Deep Work Prep",
        description: "Prepare for hard tasks.",
        durationInMinutes: 10,
        audioFileName: "10 minutes - Energy and Focus",
        categoryName: "Energy and Focus",
        odrTag: "audio_focus_03"
    ),
    Meditation(
        id: UUID(uuidString: "60000000-0000-0000-0000-000000000004")!,
        title: "Mental Clarity",
        description: "Clear the fog.",
        durationInMinutes: 15,
        audioFileName: "15 minutes - Energy and Focus",
        categoryName: "Energy and Focus",
        odrTag: "audio_focus_04"
    ),
    Meditation(
        id: UUID(uuidString: "60000000-0000-0000-0000-000000000005")!,
        title: "Flow State",
        description: "Get into the zone.",
        durationInMinutes: 20,
        audioFileName: "20 minutes - Energy and Focus",
        categoryName: "Energy and Focus",
        odrTag: "audio_focus_05"
    )
]

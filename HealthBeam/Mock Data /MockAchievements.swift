//
//  MockAchievements.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/3/26.
//


//
//  MockAchievements.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/3/26.
//

import Foundation

struct MockAchievements {
    
    /// Demo modu için TÜM başarıları KİLİDİ AÇIK ve TAMAMLANMIŞ olarak döndürür.
    static var allUnlocked: [Achievement] {
        // Mevcut statik listeyi alıp modifiye ediyoruz
        return Achievement.mockData.map { achievement in
            var unlockedAchievement = achievement
            unlockedAchievement.isLocked = false // Kilidi aç
            unlockedAchievement.progress = 1.0   // %100 tamamlandı göster (Bar dolu olsun)
            return unlockedAchievement
        }
    }
}

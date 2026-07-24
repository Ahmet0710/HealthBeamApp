//
//  MockHabits.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/3/26.
//


//
//  MockHabits.swift
//  HealthBeam
//
//  Created by Ahmet Furkan Yıldırım on 2/3/26.
//

import Foundation

struct MockHabits {
    /// Demo modu için TAMAMLANMIŞ ve yüksek streak'li örnek alışkanlıklar
    static var sampleHabits: [Habit] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Son 14 günü "tamamlanmış" olarak işaretlemek için tarih seti oluştur
        var completedDates = Set<Date>()
        for i in 0..<14 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                completedDates.insert(date)
            }
        }
        
        return [
            Habit(
                name: "Morning Jog",
                icon: "figure.run",
                color: "#FF5733", // Turuncu
                isCompleted: true,
                streak: 14,
                time: DateComponents(hour: 7, minute: 0),
                completionDates: completedDates,
                category: "Morning"
            ),
            Habit(
                name: "Drink Water",
                icon: "drop.fill",
                color: "#33C1FF", // Mavi
                isCompleted: true,
                streak: 30,
                time: DateComponents(hour: 8, minute: 0),
                completionDates: completedDates,
                category: "Morning"
            ),
            Habit(
                name: "Read Book",
                icon: "book.fill",
                color: "#A033FF", // Mor
                isCompleted: true,
                streak: 45,
                time: DateComponents(hour: 21, minute: 30),
                completionDates: completedDates,
                category: "Evening"
            ),
            Habit(
                name: "Meditation",
                icon: "brain.head.profile",
                color: "#33FF57", // Yeşil
                isCompleted: true,
                streak: 60,
                time: DateComponents(hour: 22, minute: 0),
                completionDates: completedDates,
                category: "Evening"
            ),
            Habit(
                name: "Code Review",
                icon: "laptopcomputer",
                color: "#FF33A8", // Pembe
                isCompleted: true,
                streak: 100,
                time: DateComponents(hour: 14, minute: 0),
                completionDates: completedDates,
                category: "Afternoon"
            ),
            Habit(
                name: "Walk the Dog",
                icon: "pawprint.fill",
                color: "#FFD433", // Sarı
                isCompleted: true,
                streak: 365,
                time: DateComponents(hour: 18, minute: 0),
                completionDates: completedDates,
                category: "Afternoon"
            )
        ]
    }
}

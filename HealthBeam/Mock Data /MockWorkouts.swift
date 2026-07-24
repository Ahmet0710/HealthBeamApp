import Foundation
import HealthKit

struct MockWorkouts {
    /// Apple inceleme ekibi (Review Team) için zengin antrenman geçmişi.
    static var sampleWorkouts: [Workout] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            Workout(
                type: "Running",
                duration: 45,
                averageHeartRate: 158,
                averagePace: "5:12",
                startDate: calendar.date(byAdding: .hour, value: -3, to: now)!,
                endDate: calendar.date(byAdding: .hour, value: -2, to: now)!,
                totalEnergyBurned: 540.0,
                totalDistance: 8200.0 // 8.2 km
            ),
            Workout(
                type: "Cycling",
                duration: 60,
                averageHeartRate: 132,
                averagePace: "22.5 km/h",
                startDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                endDate: calendar.date(byAdding: .day, value: -1, to: now)!.addingTimeInterval(3600),
                totalEnergyBurned: 420.0,
                totalDistance: 15500.0 // 15.5 km
            ),
            Workout(
                type: "Yoga",
                duration: 35,
                averageHeartRate: 95,
                averagePace: "-",
                startDate: calendar.date(byAdding: .day, value: -2, to: now)!,
                endDate: calendar.date(byAdding: .day, value: -2, to: now)!.addingTimeInterval(2100),
                totalEnergyBurned: 110.0,
                totalDistance: 0
            ),
            Workout(
                type: "Weight Training",
                duration: 55,
                averageHeartRate: 118,
                averagePace: "-",
                startDate: calendar.date(byAdding: .day, value: -3, to: now)!,
                endDate: calendar.date(byAdding: .day, value: -3, to: now)!.addingTimeInterval(3300),
                totalEnergyBurned: 350.0,
                totalDistance: 0
            ),
            Workout(
                type: "Swimming",
                duration: 40,
                averageHeartRate: 145,
                averagePace: "1:55/100m",
                startDate: calendar.date(byAdding: .day, value: -4, to: now)!,
                endDate: calendar.date(byAdding: .day, value: -4, to: now)!.addingTimeInterval(2400),
                totalEnergyBurned: 490.0,
                totalDistance: 1200.0 // 1.2 km
            )
        ]
    }
}

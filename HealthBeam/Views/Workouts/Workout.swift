import Foundation
import SwiftUI
import HealthKit

struct Workout: Identifiable {
    let id = UUID()
    let type: String
    let activityTypeIdentifier: UInt
    let duration: Int
    let averageHeartRate: Int
    let averagePace: String
    let startDate: Date
    let endDate: Date
    let totalEnergyBurned: Double
    let totalDistance: Double

    init(
        type: String,
        activityType: HKWorkoutActivityType? = nil,
        duration: Int,
        averageHeartRate: Int,
        averagePace: String,
        startDate: Date,
        endDate: Date,
        totalEnergyBurned: Double,
        totalDistance: Double
    ) {
        let resolvedActivityType = activityType ?? HKWorkoutActivityType.activityType(forName: type)
        self.type = type
        self.activityTypeIdentifier = resolvedActivityType.rawValue
        self.duration = duration
        self.averageHeartRate = averageHeartRate
        self.averagePace = averagePace
        self.startDate = startDate
        self.endDate = endDate
        self.totalEnergyBurned = totalEnergyBurned
        self.totalDistance = totalDistance
    }

    var activityType: HKWorkoutActivityType {
        HKWorkoutActivityType(rawValue: activityTypeIdentifier) ?? .other
    }

    var localizedType: String {
        activityType.displayName
    }

    private var visuals: WorkoutVisuals {
        WorkoutVisuals.from(activityType: activityType)
    }

    var iconName: String {
        visuals.safeSystemIcon
    }

    var tintColor: Color {
        visuals.color
    }

    var subtitle: String {
        String(localized: "Avg Pace: \(averagePace), Heart: \(averageHeartRate) bpm")
    }
}

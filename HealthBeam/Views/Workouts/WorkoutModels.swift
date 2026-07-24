import SwiftUI
import HealthKit
struct DetailedWorkoutData: Identifiable {
    let id = UUID()
    let title: String
    let value: String      
    let systemImage: String
    let color: Color
}
struct Workouts {
    let startDate: Date
    let endDate: Date
    let totalEnergyBurned: Double
    let totalDistance: Double
}
struct WorkoutDetails {
    let avgHeartRate: Double
    let calories: Double
}
struct WorkoutMetrics {
    let duration: TimeInterval
    let activeEnergyBurned: Double
    let distance: Double
    let heartRate: Double
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
    var formattedDistance: String {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        return formatter.string(fromValue: distance / 1000, unit: .kilometer)
    }
    var formattedEnergy: String {
        let formatter = EnergyFormatter()
        formatter.unitStyle = .short
        formatter.isForFoodEnergyUse = true // Kalori formatı için.
        return formatter.string(fromValue: activeEnergyBurned, unit: .kilocalorie)
    }

    var formattedHeartRate: String {
        return String(format: "%.0f bpm", heartRate)
    }
    
    var metrics: [DetailedWorkoutData] {
        [
            DetailedWorkoutData(
                title: String(localized: "Duration"),
                value: formattedDuration,
                systemImage: "clock",
                color: .blue
            ),
            DetailedWorkoutData(
                title: String(localized: "Distance"),
                value: formattedDistance,
                systemImage: "ruler",
                color: .green
            ),
            DetailedWorkoutData(
                title: String(localized: "Energy"),
                value: formattedEnergy,
                systemImage: "flame",
                color: .orange
            ),
            DetailedWorkoutData(
                title: String(localized: "Avg. Heart Rate"),
                value: formattedHeartRate,
                systemImage: "heart",
                color: .red
            )
        ]
    }
}
public extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
            case .running: return String(localized: "Running")
            case .walking: return String(localized: "Walking")
            case .cycling: return String(localized: "Cycling")
            case .swimming: return String(localized: "Swimming")
            case .hiking: return String(localized: "Hiking")
            case .yoga: return String(localized: "Yoga")
            case .functionalStrengthTraining: return String(localized: "Strength Training")
            case .traditionalStrengthTraining: return String(localized: "Weight Training")
            case .highIntensityIntervalTraining: return String(localized: "HIIT")
            case .mixedCardio: return String(localized: "Mixed Cardio")
            case .elliptical: return String(localized: "Elliptical")
            case .stairClimbing: return String(localized: "Stair Climbing")
            case .rowing: return String(localized: "Rowing")
            case .jumpRope: return String(localized: "Jump Rope")
            case .pilates: return String(localized: "Pilates")
            case .barre: return String(localized: "Barre")
            case .coreTraining: return String(localized: "Core Training")
            case .flexibility: return String(localized: "Flexibility")
            case .mindAndBody: return String(localized: "Mind & Body")
            case .stepTraining: return String(localized: "Step Training")
            case .kickboxing: return String(localized: "Kickboxing")
            case .martialArts: return String(localized: "Martial Arts")
            case .boxing: return String(localized: "Boxing")
            case .crossTraining: return String(localized: "Cross Training")
            case .fitnessGaming: return String(localized: "Fitness Gaming")
            default: return String(localized: "Other")
        }
    }

    var icon: String {
        switch self {
            case .running: return "figure.run"
            case .walking: return "figure.walk"
            case .cycling: return "bicycle"
            case .swimming: return "figure.pool.swim"
            case .hiking: return "figure.hiking"
            case .yoga: return "figure.yoga"
            case .functionalStrengthTraining, .traditionalStrengthTraining:
                return "dumbbell"
            case .highIntensityIntervalTraining: return "bolt"
            case .mixedCardio: return "heart.text.square"
            case .elliptical: return "figure.elliptical"
            case .stairClimbing: return "figure.stairs"
            case .rowing: return "figure.rower"
            case .jumpRope: return "figure.jumprope"
            case .pilates: return "figure.pilates"
            case .barre: return "figure.barre"
            case .coreTraining: return "figure.core.training"
            case .flexibility: return "figure.flexibility"
            case .mindAndBody: return "figure.mind.and.body"
            case .stepTraining: return "figure.step.training"
            case .kickboxing, .martialArts, .boxing:
                return "figure.boxing"
            case .crossTraining: return "figure.cross.training"
            case .fitnessGaming: return "gamecontroller"
            default: return "figure.mixed.cardio"
        }
    }

    var color: Color {
        switch self {
            case .running: return .blue
            case .walking: return .orange
            case .cycling: return .green
            case .swimming: return .teal
            case .hiking: return .brown
            case .yoga, .pilates, .barre, .flexibility, .mindAndBody: return .purple
            case .functionalStrengthTraining, .traditionalStrengthTraining, .crossTraining: return .indigo
            case .highIntensityIntervalTraining, .kickboxing, .martialArts, .boxing: return .red
            case .mixedCardio, .elliptical, .stairClimbing: return .pink
            case .rowing: return .cyan
            case .jumpRope: return .yellow
            default: return .gray
        }
    }
}

extension HKWorkoutActivityType {
    private static func normalizedWorkoutName(_ name: String) -> String {
        name
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "ı", with: "i")
    }

    private static func resolvedActivityType(forName name: String) -> HKWorkoutActivityType {
        let normalizedName = normalizedWorkoutName(name)

        if normalizedName.contains("run") || normalizedName.contains("kosu") {
            return .running
        }

        if normalizedName.contains("walk") || normalizedName.contains("yuruyus") || normalizedName.contains("yurume") {
            return .walking
        }

        if normalizedName.contains("cycle")
            || normalizedName.contains("cycling")
            || normalizedName.contains("bike")
            || normalizedName.contains("bicycle")
            || normalizedName.contains("bisiklet")
        {
            return .cycling
        }

        if normalizedName.contains("swim") || normalizedName.contains("yuzme") {
            return .swimming
        }

        if normalizedName.contains("hik") || normalizedName.contains("doga yuruyusu") || normalizedName.contains("trek") {
            return .hiking
        }

        if normalizedName.contains("yoga") {
            return .yoga
        }

        if normalizedName.contains("weight training")
            || normalizedName.contains("strength training")
            || normalizedName.contains("agirlik")
            || normalizedName.contains("kuvvet")
        {
            return .traditionalStrengthTraining
        }

        if normalizedName.contains("hiit") || normalizedName.contains("interval") {
            return .highIntensityIntervalTraining
        }

        if normalizedName.contains("row") || normalizedName.contains("kurek") || normalizedName.contains("kurekcilik") {
            return .rowing
        }

        if normalizedName.contains("pilates") {
            return .pilates
        }

        return .other
    }

    /// Unified accessor returning both icon and color for a workout type
    var visual: (icon: String, color: Color) {
        return (self.icon, self.color)
    }

    /// Resolve from a localized/free-form workout name to the closest HKWorkoutActivityType
    /// and return a consistent icon. This keeps UI in sync when the source is a String.
    static func icon(forName name: String) -> String {
        resolvedActivityType(forName: name).icon
    }

    /// Resolve color from a localized/free-form workout name to keep visuals consistent
    static func color(forName name: String) -> Color {
        resolvedActivityType(forName: name).color
    }

    static func activityType(forName name: String) -> HKWorkoutActivityType {
        resolvedActivityType(forName: name)
    }
}

/// Convenience struct for views that want a single source of truth from either HealthKit type or name
struct WorkoutVisuals {
    let icon: String
    let color: Color

    // From HealthKit type
    static func from(activityType: HKWorkoutActivityType) -> WorkoutVisuals {
        let v = activityType.visual
        return WorkoutVisuals(icon: v.icon, color: v.color)
    }

    // From free-form / localized name (e.g., "Yürüyüş", "Running")
    static func from(name: String) -> WorkoutVisuals {
        return WorkoutVisuals(icon: HKWorkoutActivityType.icon(forName: name),
                              color: HKWorkoutActivityType.color(forName: name))
    }

    // A safer icon that falls back to a broadly supported symbol if needed
    var safeSystemIcon: String {
        // Prefer the resolved icon, otherwise fall back to a well-supported symbol
        return icon.isEmpty ? "bolt" : icon
    }
}

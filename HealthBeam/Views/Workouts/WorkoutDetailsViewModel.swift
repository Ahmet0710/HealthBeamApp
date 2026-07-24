import SwiftUI
import HealthKit
import MapKit
import CoreLocation
import Combine
struct HeartRateZone {
    let name: String
    let range: ClosedRange<Double>
    let color: Color

    static let all: [HeartRateZone] = [
        .init(name: "Zone 1: Very Light", range: 0.5...0.6, color: .gray),
        .init(name: "Zone 2: Light (Fat Burn)", range: 0.6...0.7, color: .blue),
        .init(name: "Zone 3: Moderate (Aerobic)", range: 0.7...0.8, color: .green),
        .init(name: "Zone 4: Hard (Anaerobic)", range: 0.8...0.9, color: .orange),
        .init(name: "Zone 5: Maximum", range: 0.9...1.1, color: .red)
    ]
}
struct HeartRateZoneInfo: Identifiable {
    var id: String { zone.name }
    let zone: HeartRateZone
    var duration: TimeInterval
    var percentage: Double

    var durationFormatted: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}
struct PaceSample: Hashable {
    let timeElapsed: Double
    let pace: Double
}
struct SegmentCalories: Hashable {
    let segmentLabel: String
    let calories: Double
}
struct ElevationSample: Hashable {
    let distance: Double
    let elevation: Double
}
@MainActor
class WorkoutDetailsViewModel: ObservableObject {
    let workout: HKWorkout

    @Published var heartRateData: [HKQuantitySample] = []
    @Published var zoneDistribution: [HeartRateZoneInfo] = []
    @Published var isLoadingDetails = true
    @Published var routeLocations: [CLLocation] = []
    @Published var totalElevationGain: Double = 0.0
    @Published var paceOverTimeSamples: [PaceSample] = []
    @Published var caloriesPerSegment: [SegmentCalories] = []
    @Published var elevationProfileSamples: [ElevationSample] = []

    var activityType: HKWorkoutActivityType { workout.workoutActivityType }
    var formattedDuration: String { formatDuration(workout.duration) }
    var formattedCalories: String {
#if swift(>=5.10)
        if #available(iOS 18.0, *) {
            let activeEnergy = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()
            return formatCalories(activeEnergy)
        } else {
            return formatCalories(workout.totalEnergyBurned)
        }
#else
        return formatCalories(workout.totalEnergyBurned)
#endif
    }

    func formattedDistance(measurementSystem: MeasurementSystem) -> String {
        guard let meters = workout.totalDistance?.doubleValue(for: .meter()) else { return "--" }
        return MetricFormatter.formatDistance(meters, measurementSystem: measurementSystem)
    }

    func formattedPace(measurementSystem: MeasurementSystem) -> String {
        guard let meters = workout.totalDistance?.doubleValue(for: .meter()), meters > 0 else { return "--" }
        let durationMinutes = workout.duration / 60
        return MetricFormatter.formatPace(distanceMeters: meters, durationMinutes: durationMinutes, measurementSystem: measurementSystem)
    }

    var avgHeartRateBPM: String {
        guard !heartRateData.isEmpty else { return "--" }
        return String(format: "%.0f bpm", calculateAverageBPM())
    }
    var maxHeartRateBPM: String {
        guard let maxBPM = heartRateData.map({ $0.quantity.doubleValue(for: .count().unitDivided(by: .minute())) }).max() else { return "--" }
        return String(format: "%.0f bpm", maxBPM)
    }

    init(workout: HKWorkout) {
        self.workout = workout
    }

    func loadWorkoutDetails() async {
        self.isLoadingDetails = true
        async let heartRateSamples = HealthKitManager.shared.fetchHeartRateDuring(startDate: workout.startDate, endDate: workout.endDate)
        async let workoutRoute = HealthKitManager.shared.fetchWorkoutRoute(for: workout)

        self.heartRateData = await heartRateSamples
        self.routeLocations = await workoutRoute

        self.zoneDistribution = calculateZoneDistribution()
        self.totalElevationGain = calculateTotalElevationGain()

        self.isLoadingDetails = false
    }

    private func calculateElevationSamples() async -> [ElevationSample] {
        guard !routeLocations.isEmpty, let startLocation = routeLocations.first else { return [] }
        return routeLocations.map { location in
            ElevationSample(
                distance: location.distance(from: startLocation),
                elevation: location.altitude
            )
        }
    }

    private func calculateAverageBPM() -> Double {
        guard !heartRateData.isEmpty else { return 0 }
        let totalBPM = heartRateData.reduce(0) { sum, sample in
            sum + sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
        }
        return totalBPM / Double(heartRateData.count)
    }

    private func calculateZoneDistribution() -> [HeartRateZoneInfo] {
        guard !heartRateData.isEmpty else { return [] }
        let maxHeartRate = 190.0
        var zoneDurations: [String: TimeInterval] = [:]

        for i in 0..<(heartRateData.count - 1) {
            let currentSample = heartRateData[i]
            let nextSample = heartRateData[i+1]
            let bpm = currentSample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
            let percentageOfMax = bpm / maxHeartRate

            if let zone = HeartRateZone.all.first(where: { $0.range.contains(percentageOfMax) }) {
                let duration = nextSample.startDate.timeIntervalSince(currentSample.startDate)
                zoneDurations[zone.name, default: 0] += duration
            }
        }

        let totalDurationInZones = zoneDurations.values.reduce(0, +)
        guard totalDurationInZones > 0 else { return [] }

        return HeartRateZone.all.compactMap { zone in
            guard let duration = zoneDurations[zone.name], duration > 0 else { return nil }
            return HeartRateZoneInfo(zone: zone, duration: duration, percentage: duration / totalDurationInZones)
        }
    }

    private func calculateTotalElevationGain() -> Double {
        guard routeLocations.count > 1 else { return 0.0 }
        var gain: Double = 0.0
        for i in 1..<routeLocations.count {
            let delta = routeLocations[i].altitude - routeLocations[i-1].altitude
            if delta > 0 { gain += delta }
        }
        return gain
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
    private func formatCalories(_ energy: HKQuantity?) -> String {
        let value = energy?.doubleValue(for: .kilocalorie()) ?? 0
        return String(format: "%.0f kcal", value)
    }
    private func formatDistance(_ distance: HKQuantity?) -> String {
        let meters = distance?.doubleValue(for: .meter()) ?? 0
        return MetricFormatter.formatDistance(meters, measurementSystem: .Metric)
    }
}

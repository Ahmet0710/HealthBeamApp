import Foundation
import HealthKit

private extension String {
    var localizedHealthSignalText: String {
        NSLocalizedString(self, comment: "")
    }
}

enum HealthSignalDriverKind: String, Identifiable, CaseIterable {
    case hrv = "Lower HRV"
    case restingHeartRate = "Higher resting heart rate"
    case respiratoryRate = "Faster breathing"
    case sleep = "Sleep debt"
    case workoutLoad = "Workout strain"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .hrv:
            String(localized: "Lower HRV", comment: "Stress driver label for lower heart rate variability.")
        case .restingHeartRate:
            String(localized: "Higher resting heart rate", comment: "Stress driver label for elevated resting heart rate.")
        case .respiratoryRate:
            String(localized: "Faster breathing", comment: "Stress driver label for elevated respiratory rate.")
        case .sleep:
            String(localized: "Sleep debt", comment: "Stress driver label for insufficient sleep.")
        case .workoutLoad:
            String(localized: "Workout strain", comment: "Stress driver label for elevated workout load.")
        }
    }
}

struct HealthSignalCoreBaseline {
    let hrv: Double?
    let restingHeartRate: Double?
    let respiratoryRate: Double?
    let sleepHours: Double?
    let workoutMinutes: Double?
}

struct HealthSignalCoreSnapshot: Identifiable {
    let date: Date
    let stressScore: Double
    let readinessScore: Double
    let sleepScore: Double
    let recoveryScore: Double
    let strainScore: Double
    let hrv: Double?
    let restingHeartRate: Double?
    let respiratoryRate: Double?
    let sleepHours: Double?
    let workoutMinutes: Double
    let topDrivers: [HealthSignalDriverKind]
    let signalCount: Int

    var id: Date { date }
}

struct HealthSignalCoreBundle {
    let snapshots: [HealthSignalCoreSnapshot]
    let baseline: HealthSignalCoreBaseline
}

enum HealthSignalDemoScenario: String, CaseIterable, Identifiable {
    case recovered = "Recovered"
    case balanced = "Balanced"
    case strained = "Strained"

    var id: String { rawValue }

    var localizedTitle: String {
        rawValue.localizedHealthSignalText
    }
}

enum HealthSignalCoreEngine {
    static func makeBundle(
        dates: [Date],
        hrvByDay: [Date: Double],
        restingByDay: [Date: Double],
        respiratoryByDay: [Date: Double],
        sleepByDay: [Date: Double],
        workoutByDay: [Date: Double],
        baseline: HealthSignalCoreBaseline
    ) -> HealthSignalCoreBundle {
        let snapshots: [HealthSignalCoreSnapshot] = dates.compactMap { day -> HealthSignalCoreSnapshot? in
            let hrv = hrvByDay[day]
            let resting = restingByDay[day]
            let respiratory = respiratoryByDay[day]
            let sleep = sleepByDay[day]
            let workout = workoutByDay[day] ?? 0

            let components = [
                component(kind: .hrv, value: hrv, baseline: baseline.hrv, threshold: 0.22, maxPenalty: 28, lowerIsWorse: true),
                component(kind: .restingHeartRate, value: resting, baseline: baseline.restingHeartRate, threshold: 0.14, maxPenalty: 24, lowerIsWorse: false),
                component(kind: .respiratoryRate, value: respiratory, baseline: baseline.respiratoryRate, threshold: 0.10, maxPenalty: 16, lowerIsWorse: false),
                component(kind: .sleep, value: sleep, baseline: baseline.sleepHours, threshold: 0.18, maxPenalty: 22, lowerIsWorse: true)
            ]
            let workoutComponent = workoutComponent(today: workout, baseline: baseline.workoutMinutes)

            let penalties = components.compactMap { $0 } + (workoutComponent.map { [$0] } ?? [])
            let signalCount = [hrv, resting, respiratory, sleep].compactMap { $0 }.count
            guard signalCount > 0 else { return nil }

            let totalPenalty = penalties.reduce(0) { $0 + $1.points }
            let readinessScore = max(0, min(100, 100 - totalPenalty))
            let stressScore = min(max(10 + totalPenalty, 0), 100)
            let sleepPenalty = penalties.first(where: { $0.kind == .sleep })?.points ?? 0
            let hrvPenalty = penalties.first(where: { $0.kind == .hrv })?.points ?? 0
            let restingPenalty = penalties.first(where: { $0.kind == .restingHeartRate })?.points ?? 0
            let respiratoryPenalty = penalties.first(where: { $0.kind == .respiratoryRate })?.points ?? 0
            let workoutPenaltyValue = penalties.first(where: { $0.kind == .workoutLoad })?.points ?? 0

            return HealthSignalCoreSnapshot(
                date: day,
                stressScore: stressScore,
                readinessScore: readinessScore,
                sleepScore: max(0, min(100, 100 - sleepPenalty * 2.8)),
                recoveryScore: max(0, min(100, 100 - (hrvPenalty + restingPenalty + respiratoryPenalty) * 1.9)),
                strainScore: max(0, min(100, 100 - workoutPenaltyValue * 5)),
                hrv: hrv,
                restingHeartRate: resting,
                respiratoryRate: respiratory,
                sleepHours: sleep,
                workoutMinutes: workout,
                topDrivers: penalties.sorted { $0.points > $1.points }.prefix(2).map { $0.kind },
                signalCount: signalCount
            )
        }
        .sorted { $0.date > $1.date }

        return HealthSignalCoreBundle(snapshots: snapshots, baseline: baseline)
    }

    static func demoBundle(for scenario: HealthSignalDemoScenario) -> HealthSignalCoreBundle {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let baseline = HealthSignalCoreBaseline(
            hrv: 58,
            restingHeartRate: 57,
            respiratoryRate: 14.0,
            sleepHours: 7.8,
            workoutMinutes: 42
        )

        let dates = (0..<14).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()

        let ranges: (ClosedRange<Double>, ClosedRange<Double>, ClosedRange<Double>, ClosedRange<Double>, ClosedRange<Double>) = {
            switch scenario {
            case .recovered:
                return (56...68, 52...58, 13.1...14.2, 7.9...8.8, 18...48)
            case .balanced:
                return (48...60, 56...62, 13.8...14.8, 7.0...7.9, 24...62)
            case .strained:
                return (28...44, 63...72, 15.0...16.6, 5.6...6.8, 50...96)
            }
        }()

        var hrvByDay: [Date: Double] = [:]
        var restingByDay: [Date: Double] = [:]
        var respiratoryByDay: [Date: Double] = [:]
        var sleepByDay: [Date: Double] = [:]
        var workoutByDay: [Date: Double] = [:]

        for (index, date) in dates.enumerated() {
            let wave = sin(Double(index) * 0.7)
            hrvByDay[date] = sample(from: ranges.0, wave: wave)
            restingByDay[date] = sample(from: ranges.1, wave: -wave)
            respiratoryByDay[date] = sample(from: ranges.2, wave: Double(index % 3) * 0.25)
            sleepByDay[date] = sample(from: ranges.3, wave: cos(Double(index) * 0.5))
            workoutByDay[date] = sample(from: ranges.4, wave: sin(Double(index) * 0.9))
        }

        return makeBundle(
            dates: Array(dates),
            hrvByDay: hrvByDay,
            restingByDay: restingByDay,
            respiratoryByDay: respiratoryByDay,
            sleepByDay: sleepByDay,
            workoutByDay: workoutByDay,
            baseline: baseline
        )
    }

    private static func sample(from range: ClosedRange<Double>, wave: Double) -> Double {
        let midpoint = (range.lowerBound + range.upperBound) / 2
        let amplitude = (range.upperBound - range.lowerBound) / 2
        return min(range.upperBound, max(range.lowerBound, midpoint + amplitude * 0.55 * wave))
    }

    private static func component(
        kind: HealthSignalDriverKind,
        value: Double?,
        baseline: Double?,
        threshold: Double,
        maxPenalty: Double,
        lowerIsWorse: Bool
    ) -> (kind: HealthSignalDriverKind, points: Double)? {
        guard let value, let baseline, baseline > 0 else { return nil }
        let delta = lowerIsWorse ? max(0, baseline - value) : max(0, value - baseline)
        let normalized = min((delta / baseline) / threshold, 1)
        let points = normalized * maxPenalty
        return points > 0 ? (kind, points) : nil
    }

    private static func workoutComponent(
        today: Double,
        baseline: Double?
    ) -> (kind: HealthSignalDriverKind, points: Double)? {
        guard today > 0 else { return nil }
        guard let baseline else {
            let normalized = min(today / 120, 1)
            return normalized > 0 ? (.workoutLoad, normalized * 12) : nil
        }
        let delta = max(0, today - baseline)
        let normalized = min(delta / max(baseline + 25, 40), 1)
        let points = normalized * 10
        return points > 0 ? (.workoutLoad, points) : nil
    }
}

enum HealthSignalCoreLoader {
    static func load(
        healthKitManager: HealthKitManager,
        endDate: Date = Date()
    ) async -> HealthSignalCoreBundle {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -35, to: endDate) ?? endDate

        async let hrvSamples = healthKitManager.fetchHRV(startDate: startDate, endDate: endDate)
        async let restingSamples = healthKitManager.fetchQuantitySamples(identifier: .restingHeartRate, startDate: startDate, endDate: endDate)
        async let respiratorySamples = healthKitManager.fetchRespiratoryRate(startDate: startDate, endDate: endDate)
        async let sleepHistory = healthKitManager.fetchAllSleepData(yearsBack: 1)
        async let workouts = healthKitManager.fetchWorkouts()

        let hrvByDay = dailyAverage(samples: appleWatchOnly(await hrvSamples), unit: .secondUnit(with: .milli))
        let restingByDay = dailyAverage(samples: appleWatchOnly(await restingSamples), unit: HKUnit.count().unitDivided(by: .minute()))
        let respiratoryByDay = dailyAverage(samples: appleWatchOnly(await respiratorySamples), unit: HKUnit.count().unitDivided(by: .minute()))
        let sleepByDay = dailySleepHours(from: await sleepHistory, startDate: startDate)
        let workoutByDay = dailyWorkoutMinutes(from: appleWatchOnly(await workouts), startDate: startDate)

        let allDays = (0..<28).compactMap { calendar.date(byAdding: .day, value: -$0, to: calendar.startOfDay(for: endDate)) }
        let baselineDays = Array(allDays.dropFirst(7))
        let baseline = HealthSignalCoreBaseline(
            hrv: average(on: baselineDays, from: hrvByDay),
            restingHeartRate: average(on: baselineDays, from: restingByDay),
            respiratoryRate: average(on: baselineDays, from: respiratoryByDay),
            sleepHours: average(on: baselineDays, from: sleepByDay),
            workoutMinutes: average(on: baselineDays, from: workoutByDay)
        )

        let trendDays = Array(allDays.prefix(14)).reversed()
        return HealthSignalCoreEngine.makeBundle(
            dates: Array(trendDays),
            hrvByDay: hrvByDay,
            restingByDay: restingByDay,
            respiratoryByDay: respiratoryByDay,
            sleepByDay: sleepByDay,
            workoutByDay: workoutByDay,
            baseline: baseline
        )
    }

    private static func dailyAverage(samples: [HKQuantitySample], unit: HKUnit) -> [Date: Double] {
        let grouped = Dictionary(grouping: samples) { Calendar.current.startOfDay(for: $0.startDate) }
        return grouped.mapValues { groupedSamples in
            let values = groupedSamples.map { $0.quantity.doubleValue(for: unit) }
            return values.reduce(0, +) / Double(values.count)
        }
    }

    private static func dailySleepHours(from analyses: [DailySleepAnalysis], startDate: Date) -> [Date: Double] {
        let cutoff = Calendar.current.startOfDay(for: startDate)
        var valuesByWakeDay: [Date: Double] = [:]

        for analysis in analyses {
            let wakeDay = Calendar.current.startOfDay(for: analysis.dateInterval?.end ?? analysis.date)
            guard wakeDay >= cutoff else { continue }
            valuesByWakeDay[wakeDay] = analysis.totalAsleepTime / 3600
        }

        return valuesByWakeDay
    }

    private static func dailyWorkoutMinutes(from workouts: [HKWorkout], startDate: Date) -> [Date: Double] {
        let cutoff = Calendar.current.startOfDay(for: startDate)
        let relevant = workouts.filter { Calendar.current.startOfDay(for: $0.startDate) >= cutoff }
        let grouped = Dictionary(grouping: relevant) { Calendar.current.startOfDay(for: $0.startDate) }
        return grouped.mapValues { dayWorkouts in
            dayWorkouts.reduce(0) { $0 + ($1.duration / 60) }
        }
    }

    private static func average(on dates: [Date], from values: [Date: Double]) -> Double? {
        let matched = dates.compactMap { values[$0] }
        guard !matched.isEmpty else { return nil }
        return matched.reduce(0, +) / Double(matched.count)
    }

    private static func appleWatchOnly(_ samples: [HKQuantitySample]) -> [HKQuantitySample] {
        let filtered = samples.filter { isAppleWatchSource($0.sourceRevision.productType) }
        return filtered.isEmpty ? samples : filtered
    }

    private static func appleWatchOnly(_ workouts: [HKWorkout]) -> [HKWorkout] {
        let filtered = workouts.filter { isAppleWatchSource($0.sourceRevision.productType) }
        return filtered.isEmpty ? workouts : filtered
    }

    private static func isAppleWatchSource(_ productType: String?) -> Bool {
        guard let productType else { return false }
        return productType.lowercased().hasPrefix("watch")
    }
}

extension HealthKitManager {
    func fetchQuantitySamples(
        identifier: HKQuantityTypeIdentifier,
        startDate: Date,
        endDate: Date,
        ascending: Bool = false
    ) async -> [HKQuantitySample] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: ascending)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: quantityType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: samples ?? [])
                }
                healthStore.execute(query)
            }
            return samples as? [HKQuantitySample] ?? []
        } catch {
            return []
        }
    }
}

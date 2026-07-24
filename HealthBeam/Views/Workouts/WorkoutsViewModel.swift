import Foundation
import HealthKit
import Combine
import CoreLocation

class WorkoutsViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private var cancellables = Set<AnyCancellable>()
    private let healthKitManager = HealthKitManager.shared

    init() {
        Task {
            await self.requestAuthorizationAndFetch()
        }
    }

    @MainActor
    func requestAuthorizationAndFetch() async {
        isLoading = true
        error = nil
        
        // MARK: - App Review Demo Check
        if AppReviewManager.shared.isDemoMode {
            self.workouts = MockWorkouts.sampleWorkouts
            self.isLoading = false
            return
        }

        let hkWorkouts = await healthKitManager.fetchWorkouts()
        let mapped: [Workout] = await withTaskGroup(of: Workout?.self) { group in
            for hkWorkout in hkWorkouts {
                group.addTask {
                    let details = await self.healthKitManager.fetchWorkoutDetails(for: hkWorkout)
                    let totalDistance = hkWorkout.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0
                    let durationMinutes = hkWorkout.endDate.timeIntervalSince(hkWorkout.startDate) / 60.0
                    let pace: String
                    if totalDistance > 0 {
                        let p = durationMinutes / (totalDistance / 1000)
                        let mins = Int(p)
                        let secs = Int((p - Double(mins)) * 60)
                        pace = String(format: "%d:%02d", mins, secs)
                    } else {
                        pace = "-"
                    }
                    return await Workout(
                        type: hkWorkout.workoutActivityType.displayName,
                        activityType: hkWorkout.workoutActivityType,
                        duration: Int(durationMinutes),
                        averageHeartRate: Int(details.avgHeartRate),
                        averagePace: pace,
                        startDate: hkWorkout.startDate,
                        endDate: hkWorkout.endDate,
                        totalEnergyBurned: details.calories,
                        totalDistance: totalDistance
                    )
                }
            }
            var results = [Workout]()
            for await result in group {
                if let workout = result { results.append(workout) }
            }
            return results
        }
        
        self.workouts = mapped
        self.isLoading = false
    }

    @MainActor
    func addWorkout(_ workout: Workout) {
        self.workouts.insert(workout, at: 0)
    }
}

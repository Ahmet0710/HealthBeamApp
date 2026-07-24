import Foundation
import HealthKit
extension HealthKitManager {

    func predicateFor(range: NotificationTimeRange) -> NSPredicate? {
        switch range {
        case .allTime:
            return nil

        case .last6Months:
            let start = Calendar.current.date(
                byAdding: .month,
                value: -6,
                to: Date()
            )
            return HKQuery.predicateForSamples(
                withStart: start,
                end: Date()
            )
        }
    }
}

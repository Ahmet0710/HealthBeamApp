import HealthKit
import Foundation
struct HeartRateEventAnalyzer {

    // MARK: - HIGH HEART RATE EVENTS

    static func highHeartRateEvents(
        samples: [HKQuantitySample],
        threshold: Double,
        blockMinutes: Int = 10
    ) -> [HeartRateEvent] {

        let blockSeconds = Double(blockMinutes * 60)
        let sorted = samples.sorted { $0.startDate < $1.startDate }

        var events: [HeartRateEvent] = []
        var buffer: [HKQuantitySample] = []

        for sample in sorted {
            buffer.append(sample)

            guard let first = buffer.first else { continue }

            let duration = sample.endDate.timeIntervalSince(first.startDate)

            if duration >= blockSeconds {

                let avgHR = buffer
                    .map {
                        $0.quantity.doubleValue(
                            for: .count().unitDivided(by: .minute())
                        )
                    }
                    .reduce(0, +) / Double(buffer.count)

                if avgHR >= threshold {
                    events.append(
                        HeartRateEvent(
                            startDate: first.startDate,
                            endDate: sample.endDate,
                            averageBPM: avgHR,
                            kind: .high
                        )
                    )
                }

                buffer.removeAll()
            }
        }

        return events
    }

    // MARK: - LOW HEART RATE EVENTS

    static func lowHeartRateEvents(
        samples: [HKQuantitySample],
        threshold: Double = 40,
        blockMinutes: Int = 40
    ) -> [HeartRateEvent] {

        let blockSeconds = Double(blockMinutes * 60)
        let sorted = samples.sorted { $0.startDate < $1.startDate }

        var events: [HeartRateEvent] = []
        var buffer: [HKQuantitySample] = []

        for sample in sorted {
            buffer.append(sample)

            guard let first = buffer.first else { continue }

            let duration = sample.endDate.timeIntervalSince(first.startDate)

            if duration >= blockSeconds {

                let avgHR = buffer
                    .map {
                        $0.quantity.doubleValue(
                            for: .count().unitDivided(by: .minute())
                        )
                    }
                    .reduce(0, +) / Double(buffer.count)

                if avgHR <= threshold {
                    events.append(
                        HeartRateEvent(
                            startDate: first.startDate,
                            endDate: sample.endDate,
                            averageBPM: avgHR,
                            kind: .low
                        )
                    )
                }

                buffer.removeAll()
            }
        }

        return events
    }
}

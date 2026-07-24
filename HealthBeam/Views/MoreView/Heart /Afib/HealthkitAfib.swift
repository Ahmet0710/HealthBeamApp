import HealthKit

extension HealthKitManager {

    // MARK: - Fetch AFib Burden (Weekly)

    func fetchAFibWeeklyEntries(
        referenceDate: Date
    ) async -> [AFibWeeklyEntry] {

        guard let type = HKQuantityType.quantityType(
            forIdentifier: .atrialFibrillationBurden
        ) else { return [] }

        let calendar = Calendar.current

        guard let startDate = calendar.date(
            byAdding: .month,
            value: -6,
            to: referenceDate
        ) else { return [] }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: referenceDate
        )

        return await withCheckedContinuation { continuation in

            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in

                let quantitySamples = samples as? [HKQuantitySample] ?? []

                let grouped = Dictionary(grouping: quantitySamples) { sample -> Date in
                    calendar.dateInterval(
                        of: .weekOfYear,
                        for: sample.startDate
                    )!.start
                }

                let entries: [AFibWeeklyEntry] = grouped.compactMap {
                    weekStart, samplesInWeek in

                    guard let sample = samplesInWeek.first else { return nil }

                    let weekInterval = calendar.dateInterval(
                        of: .weekOfYear,
                        for: weekStart
                    )!

                    let value = sample.quantity.doubleValue(
                        for: HKUnit.percent()
                    )

                    return AFibWeeklyEntry(
                        weekStart: weekInterval.start,
                        weekEnd: weekInterval.end,
                        percentage: value
                    )
                }
                .sorted { $0.weekStart < $1.weekStart }

                continuation.resume(returning: entries)
            }

            self.healthStore.execute(query)
        }
    }
}

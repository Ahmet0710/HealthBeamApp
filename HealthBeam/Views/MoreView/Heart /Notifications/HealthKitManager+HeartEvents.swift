import HealthKit
import Foundation
extension HealthKitManager {

    // MARK: - GENERIC CATEGORY FETCH (LİSTE DÖNER)
    // Bu fonksiyon belirtilen tipteki (Yüksek, Düşük, Düzensiz) tüm olayları liste olarak çeker.
    
    private func fetchCategoryEvents(
        identifier: HKCategoryTypeIdentifier,
        kind: HeartRateEvent.Kind,
        range: NotificationTimeRange
    ) async -> [HeartRateEvent] {
        
        guard let type = HKCategoryType.categoryType(forIdentifier: identifier) else { return [] }
        
        let predicate = predicateFor(range: range)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, _ in
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // HKSample -> HeartRateEvent Dönüşümü
                let events = samples.map { sample in
                    // Not: Category Sample'lar direkt BPM değeri içermez (Metadata'da olabilir ama garantisi yok).
                    // Bu yüzden BPM'i 0 veriyoruz, UI tarafında "Event Detected" yazacağız.
                    HeartRateEvent(
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        averageBPM: 0,
                        kind: kind
                    )
                }
                
                continuation.resume(returning: events)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - PUBLIC FETCH FUNCTIONS

    func fetchHighHeartRateEvents(range: NotificationTimeRange) async -> [HeartRateEvent] {
        await fetchCategoryEvents(
            identifier: .highHeartRateEvent,
            kind: .high,
            range: range
        )
    }

    func fetchLowHeartRateEvents(range: NotificationTimeRange) async -> [HeartRateEvent] {
        await fetchCategoryEvents(
            identifier: .lowHeartRateEvent,
            kind: .low,
            range: range
        )
    }

    func fetchIrregularRhythmEvents(range: NotificationTimeRange) async -> [HeartRateEvent] {
        await fetchCategoryEvents(
            identifier: .irregularHeartRhythmEvent,
            kind: .irregular,
            range: range
        )
    }
    func fetchLowCardioFitnessEvents(range: NotificationTimeRange) async -> [HeartRateEvent] {
        // .lowCardioFitnessEvent tipi HealthKit'te var
        await fetchCategoryEvents(
            identifier: .lowCardioFitnessEvent,
            kind: .lowCardio,
            range: range
        )
    }
    func fetchSleepApneaEvents(range: NotificationTimeRange) async -> [HeartRateEvent] {
            await fetchCategoryEvents(
                identifier: .sleepApneaEvent,
                kind: .sleepApnea,
                range: range
            )
        }
}

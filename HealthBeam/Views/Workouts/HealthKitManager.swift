import Foundation
import _LocationEssentials
import HealthKit
import Combine
import SwiftData
struct HealthPermissionStatus: Identifiable {
    let id = UUID()
    let name: String
    let isAuthorized: Bool
    let permissionType: String
    let hkObjectType: HKObjectType
}
enum HighHeartRateThreshold: Int, CaseIterable, Identifiable {
    case bpm100 = 100
    case bpm110 = 110
    case bpm120 = 120
    case bpm130 = 130
    case bpm140 = 140
    case bpm150 = 150

    var id: Int { rawValue }

    var title: String {
        "\(rawValue) bpm"
    }
}
class HealthKitManager: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var permissionStatuses: [HealthPermissionStatus] = []
    
    let healthStore = HKHealthStore()
    let healthDataDidUpdate = PassthroughSubject<Void, Never>()
    static let shared = HealthKitManager()
    
    private init() {
        checkAuthorizationStatus()
        setupSleepObserver()
        refreshPermissionStatuses()
    }
    // MARK: - Request Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw URLError(.unsupportedURL)
        }
        let allTypesToShare: [HKObjectType?] = [
            .workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.quantityType(forIdentifier: .dietaryWater),
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKObjectType.quantityType(forIdentifier: .dietaryProtein),
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal),
            HKObjectType.quantityType(forIdentifier: .dietarySugar),
            HKObjectType.quantityType(forIdentifier: .bodyMass),
            HKObjectType.quantityType(forIdentifier: .height),
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKObjectType.quantityType(forIdentifier: .respiratoryRate),
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            HKObjectType.quantityType(forIdentifier: .leanBodyMass),
            HKObjectType.quantityType(forIdentifier: .waistCircumference),
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            HKObjectType.quantityType(forIdentifier: .bodyTemperature),
            HKObjectType.quantityType(forIdentifier: .basalBodyTemperature),
            HKQuantityType.quantityType(forIdentifier: .heartRate),
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate),
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKQuantityType.quantityType(forIdentifier: .vo2Max),
            HKQuantityType.quantityType(forIdentifier: .heartRateRecoveryOneMinute)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,


        ]
        
        let typesToShare = Set(allTypesToShare.compactMap { $0 as? HKSampleType })
        
        
        let extraTypesToRead: [HKObjectType?] = [
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKObjectType.quantityType(forIdentifier: .respiratoryRate),
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            HKObjectType.quantityType(forIdentifier: .leanBodyMass),
            HKObjectType.quantityType(forIdentifier: .appleSleepingWristTemperature),
            HKObjectType.quantityType(forIdentifier: .waistCircumference),
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            HKObjectType.quantityType(forIdentifier: .bodyTemperature),
            HKObjectType.quantityType(forIdentifier: .basalBodyTemperature),
            HKQuantityType.quantityType(forIdentifier: .heartRate),
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate),
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage),
            HKQuantityType.quantityType(forIdentifier: .vo2Max),
            HKQuantityType.quantityType(forIdentifier: .heartRateRecoveryOneMinute)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKQuantityType.quantityType(forIdentifier: .atrialFibrillationBurden),
            HKObjectType.categoryType(forIdentifier: .highHeartRateEvent)!,
            HKObjectType.categoryType(forIdentifier: .lowHeartRateEvent)!,
            HKObjectType.categoryType(forIdentifier: .irregularHeartRhythmEvent)!,
            HKObjectType.categoryType(forIdentifier: .lowCardioFitnessEvent)!,
            HKObjectType.electrocardiogramType(),
            HKObjectType.categoryType(forIdentifier: .sleepApneaEvent)!,



        ]
        
        let typesToRead = typesToShare.union(Set(extraTypesToRead.compactMap { $0 as? HKSampleType }))
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        checkAuthorizationStatus()
    }
    
    private func isReadOnlyType(_ type: HKObjectType) -> Bool {
        let readOnlyIdentifiers: [String] = [
            HKQuantityTypeIdentifier.atrialFibrillationBurden.rawValue,
            HKObjectType.electrocardiogramType().identifier,
            HKCategoryTypeIdentifier.highHeartRateEvent.rawValue,
            HKCategoryTypeIdentifier.lowHeartRateEvent.rawValue,
            HKCategoryTypeIdentifier.irregularHeartRhythmEvent.rawValue,
            HKCategoryTypeIdentifier.lowCardioFitnessEvent.rawValue,
            HKCategoryTypeIdentifier.sleepApneaEvent.rawValue
        ]
        return readOnlyIdentifiers.contains(type.identifier)
    }
    private func checkReadPermissionManually(for type: HKObjectType) async -> Bool {
        guard let sampleType = type as? HKSampleType else { return false }
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: 1, sortDescriptors: nil) { _, _, error in
                // Eğer hata yoksa Apple bu veriyi okumamıza izin veriyor demektir.
                // Hata varsa (özellikle error code 4) kullanıcı izin vermemiştir.
                if error == nil {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }
            healthStore.execute(query)
        }
    }
    
    
    // MARK: - Check All PermissionStatuses

    @MainActor
    func checkAllPermissionStatuses() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            self.permissionStatuses = []
            return
        }
        
        // 1. Paylaşılacak (Yazma) ve Okunacak tipleri netleştirelim
        let writeTypesRaw: [HKObjectType?] = [
            .workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.quantityType(forIdentifier: .dietaryWater),
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKObjectType.quantityType(forIdentifier: .dietaryProtein),
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal),
            HKObjectType.quantityType(forIdentifier: .dietarySugar),
            HKObjectType.quantityType(forIdentifier: .bodyMass),
            HKObjectType.quantityType(forIdentifier: .height),
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKObjectType.quantityType(forIdentifier: .respiratoryRate),
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            HKObjectType.quantityType(forIdentifier: .leanBodyMass),
            HKObjectType.quantityType(forIdentifier: .waistCircumference),
            HKObjectType.quantityType(forIdentifier: .bodyTemperature),
            HKObjectType.quantityType(forIdentifier: .basalBodyTemperature),
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)
        ]
        
        let readTypesRaw: [HKObjectType?] = writeTypesRaw + [
            HKQuantityType.quantityType(forIdentifier: .atrialFibrillationBurden),
            HKObjectType.categoryType(forIdentifier: .highHeartRateEvent),
            HKObjectType.categoryType(forIdentifier: .lowHeartRateEvent),
            HKObjectType.categoryType(forIdentifier: .irregularHeartRhythmEvent),
            HKObjectType.categoryType(forIdentifier: .lowCardioFitnessEvent),
            HKObjectType.electrocardiogramType(),
            HKObjectType.categoryType(forIdentifier: .sleepApneaEvent)
        ]

        let writeTypes = Set(writeTypesRaw.compactMap { $0 as? HKSampleType })
        let readTypes = Set(readTypesRaw.compactMap { $0 as? HKSampleType })
        let allUniqueTypes = readTypes.union(writeTypes)
        
        var statuses: [HealthPermissionStatus] = []
        
        for sampleType in allUniqueTypes {
            let isWriting = writeTypes.contains(sampleType)
            let isReading = readTypes.contains(sampleType)
            
            let status = self.healthStore.authorizationStatus(for: sampleType)
            var isAuthorized: Bool
            
            // KRİTİK DÜZELTME: Sadece okuma izni olanlar için manuel kontrol
            // Eğer tip 'isWriting' listesinde yoksa, o 'sadece okuma' tipidir.
            if !isWriting && isReading {
                isAuthorized = await checkReadPermissionManually(for: sampleType)
            } else {
                // Yazma izni olanlarda Apple status'ü dürüstçe söyler
                isAuthorized = (status == .sharingAuthorized)
            }
            
            // İzin metnini belirle
            let permissionText: String
            if isReading && isWriting { permissionText = "Read/Write" }
            else if isReading { permissionText = "Read" }
            else { permissionText = "Write" }
            
            let typeName = getFriendlyName(for: sampleType)
            
            statuses.append(
                HealthPermissionStatus(
                    name: NSLocalizedString(typeName, comment: "Health Data Name"),
                    isAuthorized: isAuthorized,
                    permissionType: permissionText,
                    hkObjectType: sampleType
                )
            )
        }
        
        self.permissionStatuses = statuses.sorted { $0.name < $1.name }
    }

    // Yardımcı Fonksiyon: İsimlendirme kısmını temiz tutmak için
    private func getFriendlyName(for sampleType: HKObjectType) -> String {
        let identifier = sampleType.identifier
        switch identifier {
        case HKQuantityTypeIdentifier.stepCount.rawValue: return "Step Count"
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue: return "Active Calories"
        case HKQuantityTypeIdentifier.bodyMass.rawValue: return "Body Weight"
        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue: return "Sleep Analysis"
        case HKWorkoutType.workoutType().identifier: return "Workout Routes & Sessions"
        case HKQuantityTypeIdentifier.heartRate.rawValue: return "Heart Rate"
        case HKQuantityTypeIdentifier.height.rawValue: return "Height"
        case HKQuantityTypeIdentifier.dietaryWater.rawValue: return "Water Intake"
        case HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue: return "Dietary Energy (Calories)"
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue: return "Walking + Running Distance"
        case HKQuantityTypeIdentifier.dietaryProtein.rawValue: return "Dietary Protein"
        case HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue: return "Dietary Carbohydrates"
        case HKQuantityTypeIdentifier.dietaryFatTotal.rawValue: return "Dietary Fat Total"
        case HKQuantityTypeIdentifier.dietarySugar.rawValue: return "Dietary Sugar"
        case HKQuantityTypeIdentifier.bodyFatPercentage.rawValue: return "Body Fat Percentage"
        case HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue: return "Heart Rate Variability (HRV)"
        case HKQuantityTypeIdentifier.respiratoryRate.rawValue: return "Respiratory Rate"
        case HKQuantityTypeIdentifier.basalEnergyBurned.rawValue: return "Resting Energy (BMR)"
        case HKQuantityTypeIdentifier.restingHeartRate.rawValue: return "Resting Heart Rate"
        case HKQuantityTypeIdentifier.bodyMassIndex.rawValue: return "Body Mass Index (BMI)"
        case HKQuantityTypeIdentifier.leanBodyMass.rawValue: return "Lean Body Mass"
        case HKQuantityTypeIdentifier.waistCircumference.rawValue: return "Waist Circumference"
        case HKQuantityTypeIdentifier.bodyTemperature.rawValue: return "Body Temperature"
        case HKQuantityTypeIdentifier.basalBodyTemperature.rawValue: return "Basal Body Temperature"
        case HKCorrelationTypeIdentifier.bloodPressure.rawValue: return "Blood Pressure"
        case HKQuantityTypeIdentifier.atrialFibrillationBurden.rawValue : return "A-fib Burden"
        case HKObjectType.electrocardiogramType().identifier: return "ECG"
        default:
            return identifier.components(separatedBy: ".").last?
                .replacingOccurrences(of: "QuantityTypeIdentifier", with: "")
                .replacingOccurrences(of: "CategoryTypeIdentifier", with: "")
                .capitalized ?? "Unknown Data Type"
        }
    }
    @MainActor
    public func refreshPermissionStatuses() {
        Task {
            var readTypes = Set(permissionStatuses.map { $0.hkObjectType as! HKSampleType })
            if readTypes.isEmpty {
                if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
                    readTypes.insert(steps)
                }
            }
            healthStore.getRequestStatusForAuthorization(toShare: [], read: readTypes) { status, error in
                Task { @MainActor in
                    await self.checkAllPermissionStatuses()
                }
            }
        }
    }
    
    // MARK: - ECG

    func fetchECGEntries(limit: Int = 10) async -> [ECGEntry] {
        let ecgType = HKObjectType.electrocardiogramType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: ecgType, predicate: nil, limit: limit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard let ecgSamples = samples as? [HKElectrocardiogram], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                
                let entries = ecgSamples.map { sample in
                    ECGEntry(
                        id: sample.uuid,
                        date: sample.startDate,
                        classification: sample.classification,
                        averageHeartRate: sample.averageHeartRate?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                        sample: sample
                    )
                }
                continuation.resume(returning: entries)
            }
            healthStore.execute(query)
        }
    }
    
    func fetchECGWaveform(for ecgSample: HKElectrocardiogram) async -> [(time: Double, voltage: Double)] {
        return await withCheckedContinuation { continuation in
            var samples: [(Double, Double)] = []
            
            // HKElectrocardiogramQuery kullanarak voltaj verilerini okuyoruz
            let query = HKElectrocardiogramQuery(ecgSample) { (query, result) in
                switch result {
                case .measurement(let measurement):
                    // .appleWatchSimilarToLeadI : Apple Watch'un ölçtüğü Lead I verisi
                    if let voltageQuantity = measurement.quantity(for: .appleWatchSimilarToLeadI) {
                        let mvUnit = HKUnit.voltUnit(with: .milli)
                        let voltageValue = voltageQuantity.doubleValue(for: mvUnit)
                        samples.append((measurement.timeSinceSampleStart, voltageValue))
                    }
                case .done:
                    continuation.resume(returning: samples)
                case .error(let error):
                    print("ECG Waveform error: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    
                @unknown default:
                    break
                }
            }
            healthStore.execute(query)
        }
    }
    // MARK: - Sleep

    
    private func setupSleepObserver() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return }

        let query = HKObserverQuery(sampleType: sleepType, predicate: nil, updateHandler: { [weak self] (query, completionHandler, error) in
            guard let self = self else {
                completionHandler()
                return }
            guard error == nil else {
                return
            }
            Task { @MainActor in
                self.healthDataDidUpdate.send()
            }
            completionHandler()
        })
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: sleepType, frequency: .immediate) { (success, error) in
            if success {
            } else if error != nil {
            }
        }
    }
    
    func fetchAllSleepData(yearsBack: Int = 10) async -> [DailySleepAnalysis] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -yearsBack, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let query = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)]
        )
        
        do {
            let samples = try await query.result(for: healthStore)
            guard !samples.isEmpty else { return [] }
            
            let samplesByDay = Dictionary(grouping: samples) { sample in
                Calendar.current.startOfDay(for: sample.endDate)
            }
            
            var dailyAnalyses: [DailySleepAnalysis] = []
            for (date, samplesForDay) in samplesByDay {
                let periods: [SleepStagePeriod] = samplesForDay.compactMap { sample in
                    guard let type = SleepStage.from(hkValue: sample.value) else { return nil }
                    return SleepStagePeriod(type: type, startDate: sample.startDate, endDate: sample.endDate)
                }

                if !periods.isEmpty {
                    let analysis = DailySleepAnalysis(date: date, stagePeriods: periods)
                    dailyAnalyses.append(analysis)
                }
            }
            return dailyAnalyses.sorted(by: { $0.date > $1.date })

        } catch {
            return []
        }
    }
    func fetchLastNightSleepDuration() async -> TimeInterval {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let samplePredicate = HKSamplePredicate.categorySample(type: sleepType, predicate: predicate)
        let query = HKSampleQueryDescriptor<HKCategorySample>(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)]
        )
        do {
            let results = try await query.result(for: healthStore)
            let asleepStates: [HKCategoryValueSleepAnalysis] = [.asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM]
            let totalSleepTime = results
                .filter { sample in
                    guard let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return false }
                    return asleepStates.contains(sleepValue)
                }
                .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            return totalSleepTime
        } catch {
            return 0
        }
    }
    func fetchLastNightSleepTimes() async -> (start: Date, end: Date)? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let samplePredicate = HKSamplePredicate.categorySample(type: sleepType, predicate: predicate)
        let query = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        do {
            let asleepStates: [HKCategoryValueSleepAnalysis] = [.asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM]
            let results = try await query.result(for: healthStore)
                .filter { sample in
                    guard let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return false }
                    return asleepStates.contains(sleepValue)
                }
            guard let firstSleepSample = results.first, let lastSleepSample = results.last else { return nil }
            return (start: firstSleepSample.startDate, end: lastSleepSample.endDate)
        } catch {
            return nil
        }
    }
    func fetchSleepStreak(sleepGoalInHours: Double) async -> Int {
        let sleepGoalInSeconds = sleepGoalInHours * 3600
        let allSleep = await fetchAllSleepData()
        guard !allSleep.isEmpty else { return 0 }
        let successfulDays = Set(
            allSleep.filter { $0.totalAsleepTime >= sleepGoalInSeconds }
                    .map { Calendar.current.startOfDay(for: $0.date) }
        ).sorted(by: >)
        guard let mostRecentDay = successfulDays.first else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        if mostRecentDay < yesterday { return 0 }
        var streak = 1
        var previousDayToFind = Calendar.current.date(byAdding: .day, value: -1, to: mostRecentDay)!
        for i in 1..<successfulDays.count {
            if successfulDays[i] == previousDayToFind {
                streak += 1
                previousDayToFind = Calendar.current.date(byAdding: .day, value: -1, to: previousDayToFind)!
            } else {
                break
            }
        }
        return streak
    }
    
    // MARK: - Check Authorization Status

    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async { self.isAuthorized = false }
            return
        }
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        DispatchQueue.main.async {
            switch status {
            case .sharingAuthorized:
                self.isAuthorized = true
            case .sharingDenied:
                self.isAuthorized = false
            case .notDetermined:
                self.isAuthorized = false
            @unknown default:
                self.isAuthorized = false
            }
        }
    }

    // MARK: - Water

    
    func saveWaterIntake(liters: Double, date: Date = Date()) async throws {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            throw NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Water type is not available."])
        }
        let quantity = HKQuantity(unit: HKUnit.liter(), doubleValue: liters)
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date, end: date)
        try await healthStore.save(sample)

        Task { @MainActor in
            self.healthDataDidUpdate.send()
        }
    }
    
    func fetchTodaysWaterIntake() async -> Double {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return 0 }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let descriptor = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: waterType, predicate: predicate), options: .cumulativeSum)
        do {
            let result = try await descriptor.result(for: healthStore)
            return result?.sumQuantity()?.doubleValue(for: HKUnit.liter()) ?? 0
        } catch {
            return 0
        }
    }
    
    func deleteWaterSample(uuid: UUID) async {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            Task { @MainActor in
                self.healthDataDidUpdate.send()
                        }
                return
            }
            let predicate = HKQuery.predicateForObject(with: uuid)
            do { try await healthStore.deleteObjects(of: waterType, predicate: predicate) }
            catch {
        }
    }
    
    public func fetchRecentWaterSamples() async -> [WaterLogEntry] {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return [] }
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        let sortDescriptor = SortDescriptor(\HKQuantitySample.startDate, order: .reverse)
        let descriptor = HKSampleQueryDescriptor<HKQuantitySample>(predicates: [.quantitySample(type: waterType, predicate: predicate)], sortDescriptors: [sortDescriptor])
        do {
            let samples = try await descriptor.result(for: healthStore)
            return samples.map { sample in
                WaterLogEntry(
                    id: sample.uuid,
                    amountLiters: sample.quantity.doubleValue(for: HKUnit.liter()),
                    date: sample.startDate
                )
            }
        }
        catch
        {
            return []
        }
    }
    
    // MARK: - Meal
    func saveMealToHealthKit(_ meal: Meal) async {
        let mealDate = meal.time
        var samples: [HKQuantitySample] = []
        let metadata: [String: Any] = [HKMetadataKeyExternalUUID: meal.id.uuidString]
        
    func createSample(value: Double, identifier: HKQuantityTypeIdentifier, unit: HKUnit) -> HKQuantitySample? {
            guard value > 0, let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            return HKQuantitySample(type: type, quantity: quantity, start: mealDate, end: mealDate, metadata: metadata)
        }
        
        if let calorieSample = createSample(value: meal.calories, identifier: .dietaryEnergyConsumed, unit: HKUnit.kilocalorie()) { samples.append(calorieSample) }
        if let proteinSample = createSample(value: meal.protein, identifier: .dietaryProtein, unit: HKUnit.gram()) { samples.append(proteinSample) }
        if let carbsSample = createSample(value: meal.carbs, identifier: .dietaryCarbohydrates, unit: HKUnit.gram()) { samples.append(carbsSample) }
        if let fatSample = createSample(value: meal.fat, identifier: .dietaryFatTotal, unit: HKUnit.gram()) { samples.append(fatSample) }
        if let sugarSample = createSample(value: meal.sugar, identifier: .dietarySugar, unit: HKUnit.gram()) { samples.append(sugarSample) }
        guard !samples.isEmpty else { return }
        do {
            try await healthStore.save(samples)
            Task { @MainActor in
                self.healthDataDidUpdate.send()
            }
        } catch {
        }
    }

    func deleteMealFromHealthKit(mealID: UUID) async {
        let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyExternalUUID, allowedValues: [mealID.uuidString])
        let nutrientTypeIdentifiers: [HKQuantityTypeIdentifier] = [.dietaryEnergyConsumed, .dietaryProtein, .dietaryCarbohydrates, .dietaryFatTotal, .dietarySugar]
        for typeIdentifier in nutrientTypeIdentifiers {
            guard let type = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else { continue }
            do {
                try await healthStore.deleteObjects(of: type, predicate: predicate)
            } catch {
            }
        }
    }
    
    func deleteMealFromHealthKit(meal: Meal) async {
        let nutrientTypes: [HKQuantityTypeIdentifier] = [
            .dietaryEnergyConsumed, .dietaryProtein, .dietaryCarbohydrates,
            .dietaryFatTotal, .dietarySugar
        ]
        let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyExternalUUID, allowedValues: [meal.id.uuidString])
        for typeIdentifier in nutrientTypes {
            guard let type = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else { continue }
            do {
                try await healthStore.deleteObjects(of: type, predicate: predicate)
            } catch {
            }
        }
        Task { @MainActor in
            self.healthDataDidUpdate.send()
        }
    }
        
    // MARK: - Workouts

    func fetchWorkouts() async -> [HKWorkout] {
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout()],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )
        do {
            return try await descriptor.result(for: healthStore)
        } catch {
            return []
        }
    }

    public func saveWorkoutToHealthKit(workout: Workout, activityType: HKWorkoutActivityType) async throws {
        let start = workout.startDate
        let end = workout.endDate
        let calories = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: workout.totalEnergyBurned)
        let distance = HKQuantity(unit: HKUnit.meter(), doubleValue: workout.totalDistance)
        let heartRate = HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: Double(workout.averageHeartRate))
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        try await builder.beginCollection(at: start)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.endCollection(withEnd: end) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if !success {
                    continuation.resume(throwing: NSError(domain: "HealthKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "End collection failed"]))
                } else {
                    continuation.resume()
                }
            }
        }

        let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let energySample = HKQuantitySample(type: activeEnergyType, quantity: calories, start: start, end: end)
        let distanceSample = HKQuantitySample(type: distanceType, quantity: distance, start: start, end: end)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            builder.add([energySample, distanceSample]) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if !success {
                    continuation.resume(throwing: NSError(domain: "HealthKitManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Add samples failed"]))
                } else {
                    continuation.resume()
                }
            }
        }

        _ = try await builder.finishWorkout()
        if workout.averageHeartRate > 0 {
            if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
                let hrSample = HKQuantitySample(
                    type: heartRateType,
                    quantity: heartRate,
                    start: start,
                    end: end
                )
                try await healthStore.save(hrSample)
            }
        }
        Task { @MainActor in
            self.healthDataDidUpdate.send()
        }
    }

    func fetchSteps(for date: Date) async -> Double {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let descriptor = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: stepType, predicate: predicate), options: .cumulativeSum)
        do {
            let result = try await descriptor.result(for: healthStore)
            return result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
        } catch {
            return 0
        }
    }

    func fetchMaxDailyStepCount() async -> Double {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .year, value: -10, to: endDate) else { return 0 }
        let anchorDate = calendar.startOfDay(for: endDate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, error in
                guard error == nil, let results else {
                    continuation.resume(returning: 0)
                    return
                }

                var maxSteps = 0.0
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let dailySteps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    maxSteps = max(maxSteps, dailySteps)
                }

                continuation.resume(returning: maxSteps)
            }

            self.healthStore.execute(query)
        }
    }

    func fetchTotalWorkoutCount() async -> Int {
        let workouts = await fetchWorkouts()
        return workouts.count
    }

    func fetchHighestEnergyBurnedInWorkout() async -> Double {
        let workouts = await fetchWorkouts()
        let activeEnergyType = HKQuantityType(.activeEnergyBurned)
        let maxCalories = workouts.compactMap {
            $0.statistics(for: activeEnergyType)?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie())
        }.max()
        return maxCalories ?? 0
    }
    
    func fetchLongestWorkoutDuration() async -> Double {
        let workouts = await fetchWorkouts()
        return workouts.map { $0.duration / 60 }.max() ?? 0
    }

    func fetchMaxDistanceInWorkout() async -> Double {
        let workouts = await fetchWorkouts()
        let maxDistance = workouts.compactMap { $0.totalDistance?.doubleValue(for: HKUnit.meter()) }.max()
        return (maxDistance ?? 0) / 1000
    }
    
    
    func fetchTotalEnergyBurnedAllTime() async -> Double {
        let workouts = await fetchWorkouts()
        var totalCalories: Double = 0
        let activeEnergyType = HKQuantityType(.activeEnergyBurned)
        for workout in workouts {
            if let statistics = workout.statistics(for: activeEnergyType),
               let calories = statistics.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) {
                totalCalories += calories
            }
        }
        return totalCalories
    }
    func fetchCurrentWorkoutStreak() async -> Int {
        let workouts = await fetchWorkouts()
        guard !workouts.isEmpty else { return 0 }
        let workoutDays = Set(workouts.map { Calendar.current.startOfDay(for: $0.startDate) }).sorted(by: >)
        guard let mostRecentWorkoutDate = workoutDays.first else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        if mostRecentWorkoutDate < yesterday { return 0 }
        var streak = 1
        var previousDayToFind = Calendar.current.date(byAdding: .day, value: -1, to: mostRecentWorkoutDate)!
        for i in 1..<workoutDays.count {
            if workoutDays[i] == previousDayToFind {
                streak += 1
                previousDayToFind = Calendar.current.date(byAdding: .day, value: -1, to: previousDayToFind)!
            } else {
                break
            }
        }
        return streak
    }
    func checkAnyWorkoutAfter(hour: Int) async -> Bool {
        let workouts = await fetchWorkouts()
        return workouts.contains { Calendar.current.component(.hour, from: $0.startDate) >= hour }
    }

    func checkIfWorkoutTypeExists(activityType: HKWorkoutActivityType) async -> Bool {
        let workouts = await fetchWorkouts()
        return workouts.contains { $0.workoutActivityType == activityType }
    }
    
    func fetchWorkoutDetails(for workout: HKWorkout) async -> WorkoutDetails {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return WorkoutDetails(avgHeartRate: 0, calories: 0)
        }
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        let avgHeartRate: Double = await {
            let heartRateSamplePredicate = HKSamplePredicate.quantitySample(type: heartRateType, predicate: predicate)
            let heartRateDescriptor = HKStatisticsQueryDescriptor(predicate: heartRateSamplePredicate, options: .discreteAverage)
            if let result = try? await heartRateDescriptor.result(for: healthStore), let avg = result.averageQuantity() {
                return avg.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            }
            return 0
        }()
        let totalCalories: Double = await {
            let calorieSamplePredicate = HKSamplePredicate.quantitySample(type: energyType, predicate: predicate)
            let calorieDescriptor = HKStatisticsQueryDescriptor(predicate: calorieSamplePredicate, options: .cumulativeSum)
            if let result = try? await calorieDescriptor.result(for: healthStore), let sum = result.sumQuantity() {
                return sum.doubleValue(for: HKUnit.kilocalorie())
            }
            return 0
        }()
        return WorkoutDetails(avgHeartRate: avgHeartRate, calories: totalCalories)
    }
    
    func fetchHeartRateDuring(startDate: Date, endDate: Date) async -> [HKQuantitySample] {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = SortDescriptor(\HKQuantitySample.startDate, order: .forward)
        let query = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: heartRateType, predicate: predicate)],
            sortDescriptors: [sortDescriptor]
        )
        do {
            let samples = try await query.result(for: healthStore)
            return samples
        } catch {
            return []
        }
    }
    
    func fetchHRV(startDate: Date, endDate: Date) async -> [HKQuantitySample] {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: samples ?? [])
                }
                self.healthStore.execute(query)
            }
            return samples as? [HKQuantitySample] ?? []
        } catch {
            return []
        }
    }
    
    func fetchWorkoutRoute(for workout: HKWorkout) async -> [CLLocation] {
    let routeType = HKSeriesType.workoutRoute()
    let predicate = HKQuery.predicateForObjects(from: workout)
    let query = HKSampleQueryDescriptor(
        predicates: [.sample(type: routeType, predicate: predicate)],
        sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
    )
    do {
        let routes = try await query.result(for: healthStore)
        guard let workoutRoute = routes.first as? HKWorkoutRoute else { return [] }

        let locations = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CLLocation], Error>) in
            let accumulator = LocationsAccumulator()
            let routeQuery = HKWorkoutRouteQuery(route: workoutRoute) { _, locationsOrNil, done, errorOrNil in
                if let error = errorOrNil {
                    continuation.resume(throwing: error)
                    return
                }
                if let locations = locationsOrNil {
                    Task {
                        await accumulator.add(locations)
                    }
                }
                if done {
                    Task {
                        let all = await accumulator.all()
                        continuation.resume(returning: all)
                    }
                }
            }
            self.healthStore.execute(routeQuery)
        }
        return locations
    } catch {
        print("Failed to fetch workout route: \(error.localizedDescription)")
        return []
    }
}

    func fetchStepCount(for date: Date) async -> Double {
    guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
    let startOfDay = Calendar.current.startOfDay(for: date)
    let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
    let descriptor = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: stepType, predicate: predicate), options: .cumulativeSum)
    do {
        let result = try await descriptor.result(for: healthStore)
        return result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
    } catch {
        return 0
    }
}
    
    func fetchRestingHeartRate(for date: Date) async -> Double {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return 0 }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let descriptor = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: hrType, predicate: predicate), options: .discreteAverage)
        do {
            let result = try await descriptor.result(for: healthStore)
            return result?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) ?? 0
        } catch {
            return 0
        }
    }

    
    

    // MARK: - Measurements
    
    public func saveMeasurement(_ entry: MeasurementEntry) async throws {
        let quantityTypeAndUnit: (HKQuantityType, HKUnit)? = {
            switch entry.type {
            case .weight: return (HKQuantityType.quantityType(forIdentifier: .bodyMass)!, HKUnit.gramUnit(with: .kilo))
            case .height: return (HKQuantityType.quantityType(forIdentifier: .height)!, HKUnit.meterUnit(with: .centi))
            case .bodyFatPercentage: return (HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!, HKUnit.percent())
            case .leanBodyMass: return (HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!, HKUnit.gramUnit(with: .kilo))
            case .waistCircumference: return (HKQuantityType.quantityType(forIdentifier: .waistCircumference)!, HKUnit.meterUnit(with: .centi))
            case .bodyTemperature: return (HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!, HKUnit.degreeCelsius())
            case .basalBodyTemperature: return (HKQuantityType.quantityType(forIdentifier: .basalBodyTemperature)!, HKUnit.degreeCelsius())
            case .wristTemperature:
                return (HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature)!, HKUnit.degreeCelsius())
            case .bodyMassIndex: return (HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!, HKUnit.count())
            }
        }()
        guard let (quantityType, unit) = quantityTypeAndUnit else { throw URLError(.badURL) }
        let quantity = HKQuantity(unit: unit, doubleValue: entry.value)
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: entry.date, end: entry.date)
        try await healthStore.save(sample)
    }
    
    func fetchRespiratoryRate(startDate: Date, endDate: Date) async -> [HKQuantitySample] {
        guard let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(sampleType: respiratoryRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: samples ?? [])
                }
                self.healthStore.execute(query)
            }
            return samples as? [HKQuantitySample] ?? []
        } catch {
            return []
        }
    }
      
    func fetchBasalEnergyBurned(for date: Date) async -> Double {
        guard let basalType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else { return 0 }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let descriptor = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: basalType, predicate: predicate), options: .cumulativeSum)
        do {
            let result = try await descriptor.result(for: healthStore)
            return result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
        } catch {
            return 0
        }
    }


    func fetchBodyMassIndex(for date: Date) async -> Double {
        guard let bmiType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) else { return 0 }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let descriptor = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: bmiType, predicate: predicate), options: .mostRecent)
        do {
            let result = try await descriptor.result(for: healthStore)
            return result?.mostRecentQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
        } catch {
            return 0
        }
    }

    func fetchLeanBodyMass(for date: Date) async -> Double {
        guard let lbmType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass) else { return 0 }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let descriptor = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: lbmType, predicate: predicate), options: .mostRecent)
        do {
            let result = try await descriptor.result(for: healthStore)
            return result?.mostRecentQuantity()?.doubleValue(for: HKUnit.gramUnit(with: .kilo)) ?? 0
        } catch {
            return 0
        }
    }

    public func fetchHealthMeasurements() async -> [MeasurementEntry] {
        _ = Date()
        var allEntries: [MeasurementEntry] = []
        let calendar = Calendar.current
        
        await withTaskGroup(of: [MeasurementEntry].self) { group in
            for type in MeasurementType.allCases {
                group.addTask {
                    guard let (quantityType, unit) = await hkTypeAndUnit(for: type) else {
                        return []
                    }
                    let predicate = HKQuery.predicateForSamples(withStart: calendar.date(byAdding: .year, value: -10, to: Date()), end: Date(), options: .strictStartDate)
                    let sortDescriptor = SortDescriptor(\HKQuantitySample.startDate, order: .reverse)
                    let descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
                        predicates: [.quantitySample(type: quantityType, predicate: predicate)],
                        sortDescriptors: [sortDescriptor]
                    )
                    do {
                        let samples = try await descriptor.result(for: self.healthStore)
                        return samples.map { sample in
                            MeasurementEntry(type: type, value: sample.quantity.doubleValue(for: unit), date: sample.startDate)
                        }
                    } catch {
                        return []
                    }
                }
            }
            for await entries in group {
                allEntries.append(contentsOf: entries)
            }
        }
        return allEntries.sorted { $0.date > $1.date }
    }

    func fetchTodaysSum(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            print("Geçersiz HealthKit Quantity Type Identifier: \(identifier.rawValue)")
            return 0
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    print("\(identifier.rawValue) verisi çekilirken hata oluştu: \(error.localizedDescription)")
                    continuation.resume(returning: 0)
                    return
                }
                let sum = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: sum)
            }
            self.healthStore.execute(query)
        }
    }
    
    
    // MARK: - Heart

    func fetchHeartEntries(
        metric: HeartMetric,
        range: HeartTimeRange,
        referenceDate: Date
    ) async -> [HeartEntry] {

        switch metric {
        case .heartRate,
             .restingHeartRate,
             .heartRateVariability:
            switch range {
            case .day:
                return await fetchDailyHeartRate(
                    metric: metric,
                    date: referenceDate
                )
            case .week, .month, .year :
                return await fetchAggregatedHeartRate(
                    metric: metric,
                    range: range,
                    date: referenceDate
                )
            }
        case .walkingHeartRate,
             .cardioFitness:
            let interval = dateInterval(for: range, date: referenceDate)
            return await fetchSparseHeartMetric(
                metric: metric,
                startDate: interval.start,
                endDate: interval.end
            )
        case .cardioRecovery:
            let interval = dateInterval(for: range, date: referenceDate)
            return await fetchSparseHeartMetric(
                metric: metric,
                startDate: interval.start,
                endDate: interval.end
            )
        }
    }
    
    private func quantityType(for metric: HeartMetric) -> HKQuantityType? {
        switch metric {
        case .heartRate:
            return HKQuantityType.quantityType(forIdentifier: .heartRate)

        case .restingHeartRate:
            return HKQuantityType.quantityType(forIdentifier: .restingHeartRate)

        case .heartRateVariability:
            return HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)

        case .walkingHeartRate:
            return HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage)

        case .cardioFitness:
            return HKQuantityType.quantityType(forIdentifier: .vo2Max)
        case .cardioRecovery:
            return HKQuantityType.quantityType(forIdentifier: .heartRateRecoveryOneMinute)
        }
    }
    
    func fetchHourlyHeartRate(
        metric: HeartMetric,
        date: Date
    ) async -> [HeartEntry] {

        guard let type = quantityType(for: metric) else { return [] }
        let unit = HealthKitManager.unit(for: metric)

        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .hour, for: date) else { return [] }

        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end
        )

        return await withCheckedContinuation { continuation in

            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage],
                anchorDate: interval.start,
                intervalComponents: DateComponents(minute: 1)
            )

            query.initialResultsHandler = { _, collection, _ in
                guard let collection else {
                    continuation.resume(returning: [])
                    return
                }

                let results: [HeartEntry] = collection.statistics().compactMap { stat in
                    guard let quantity = stat.averageQuantity() else { return nil }

                    let value = quantity.doubleValue(for: unit)

                    return HeartEntry(
                        metric: metric,
                        value: value,
                        date: stat.startDate
                    )
                }

                continuation.resume(returning: results)
            }

            self.healthStore.execute(query)
        }
    }
    
    private func minuteBuckets(
        entries: [HeartEntry],
        start: Date,
        end: Date,
        stepMinutes: Int
    ) -> [HeartChartDataPoint] {

        let calendar = Calendar.current
        var current = start
        var result: [HeartChartDataPoint] = []

        while current < end {

            guard let next = calendar.date(byAdding: .minute, value: stepMinutes, to: current) else {
                break
            }

            let values = entries
                .filter { $0.date >= current && $0.date < next }
                .map { $0.value }

            let avg: Double?

            if values.isEmpty {
                avg = nil
            } else {
                avg = values.reduce(0, +) / Double(values.count)
            }

            result.append(
                HeartChartDataPoint(
                    date: current,
                    HeartRate: avg!
                )
            )
            current = next
        }
        return result
    }
        
    func fetchDailyHeartRate(
        metric: HeartMetric,
        date: Date
    ) async -> [HeartEntry] {

        guard let type = quantityType(for: metric) else { return [] }
        let unit = HealthKitManager.unit(for: metric)

        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .day, for: date) else { return [] }

        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end
        )

        return await withCheckedContinuation { continuation in

            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage],
                anchorDate: interval.start,
                intervalComponents: DateComponents(minute: 15)
            )

            query.initialResultsHandler = { _, collection, _ in
                guard let collection else {
                    continuation.resume(returning: [])
                    return
                }

                let results: [HeartEntry] = collection.statistics().compactMap { stat in
                    guard let quantity = stat.averageQuantity() else { return nil }

                    let value = quantity.doubleValue(for: unit)

                    return HeartEntry(
                        metric: metric,
                        value: value,
                        date: stat.startDate
                    )
                }

                continuation.resume(returning: results)
            }

            self.healthStore.execute(query)
        }
    }
    nonisolated static func unit(for metric: HeartMetric) -> HKUnit {
           switch metric {
           case .heartRate,
                .restingHeartRate,
                .walkingHeartRate:
               return HKUnit.count().unitDivided(by: .minute())

           case .heartRateVariability:
               return HKUnit.secondUnit(with: .milli)

           case .cardioFitness:
               return HKUnit(from: "ml/kg*min")
           case .cardioRecovery:
               return HKUnit.count().unitDivided(by: .minute())
           }
       }
    
    func fetchAggregatedHeartRate(
        metric: HeartMetric,
        range: HeartTimeRange,
        date: Date
    ) async -> [HeartEntry] {

        guard let type = quantityType(for: metric) else { return [] }
        let unit = Self.unit(for: metric)

        let calendar = Calendar.current
        let interval: DateInterval
        let components: DateComponents

        switch range {
        case .week:
            interval = calendar.dateInterval(of: .weekOfYear, for: date)!
            components = DateComponents(day: 1)

        case .month:
            interval = calendar.dateInterval(of: .month, for: date)!
            components = DateComponents(weekOfYear: 1)

        default:
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end
        )

        return await withCheckedContinuation { continuation in

            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage],
                anchorDate: interval.start,
                intervalComponents: components
            )

            query.initialResultsHandler = { _, collection, _ in
                guard let collection else {
                    continuation.resume(returning: [])
                    return
                }

                let results: [HeartEntry] = collection.statistics().compactMap { stat in
                    guard let quantity = stat.averageQuantity() else { return nil }

                    let value = quantity.doubleValue(for: unit)

                    return HeartEntry(
                        metric: metric,
                        value: value,
                        date: stat.startDate
                    )
                }

                continuation.resume(returning: results)
            }

            self.healthStore.execute(query)
        }
    }
    
    func fetchWalkingHeartRate(
        date: Date
    ) async -> [HeartEntry] {

        guard let type = HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage)
        else { return [] }

        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .day, for: date) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end
        )

        return await withCheckedContinuation { continuation in

            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage],
                anchorDate: interval.start,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, collection, _ in
                guard let stat = collection?.statistics().first,
                      let quantity = stat.averageQuantity()
                else {
                    continuation.resume(returning: [])
                    return
                }

                Task {
                    let unit = await MainActor.run {
                        HealthKitManager.unit(for: .walkingHeartRate)
                    }

                    let value = quantity.doubleValue(for: unit)

                    continuation.resume(returning: [
                        HeartEntry(
                            metric: .walkingHeartRate,
                            value: value,
                            date: stat.startDate
                        )
                    ])
                }
            }

            healthStore.execute(query)
        }
    }
    
    func fetchCardioFitness(
        date: Date
    ) async -> [HeartEntry] {

        guard let type = HKQuantityType.quantityType(forIdentifier: .vo2Max)
        else { return [] }

        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .year, for: date) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end
        )

        return await withCheckedContinuation { continuation in

            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in

                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                Task {
                    let unit = await MainActor.run {
                        HealthKitManager.unit(for: .cardioFitness)
                    }

                    let entries = samples.map {
                        HeartEntry(
                            metric: .cardioFitness,
                            value: $0.quantity.doubleValue(for: unit),
                            date: $0.startDate
                        )
                    }

                    continuation.resume(returning: entries)
                }
            }

            healthStore.execute(query)
        }
    }

    
    func fetchSparseHeartMetric(
        metric: HeartMetric,
        startDate: Date,
        endDate: Date
    ) async -> [HeartEntry] {

        guard let type = quantityType(for: metric) else { return [] }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate
        )

        return await withCheckedContinuation { continuation in

            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
                ]
            ) { _, samples, _ in

                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let unit = HealthKitManager.unit(for: metric)

                let entries = samples.map {
                    HeartEntry(
                        metric: metric,
                        value: $0.quantity.doubleValue(for: unit),
                        date: $0.startDate
                    )
                }

                continuation.resume(returning: entries)
            }

            self.healthStore.execute(query)
        }
    }
    
    func fetchYearlyHeartMetric(
        metric: HeartMetric,
        year: Date
    ) async -> [HeartEntry] {

        guard let type = quantityType(for: metric) else { return [] }

        let calendar = Calendar.current
        guard let yearInterval = calendar.dateInterval(of: .year, for: year) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: yearInterval.start,
            end: yearInterval.end
        )

        return await withCheckedContinuation { continuation in

            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage],
                anchorDate: yearInterval.start,
                intervalComponents: DateComponents(month: 1)
            )

            query.initialResultsHandler = { _, collection, _ in
                guard let collection else {
                    continuation.resume(returning: [])
                    return
                }

                let results: [HeartEntry] = collection.statistics().compactMap { stat in
                    guard let quantity = stat.averageQuantity() else { return nil }
                    let value = quantity.doubleValue(for: HealthKitManager.unit(for: metric))

                    return HeartEntry(
                        metric: metric,
                        value: value,
                        date: stat.startDate
                    )
                }

                continuation.resume(returning: results)
            }

            self.healthStore.execute(query)
        }
    }

    
    func fetchBloodPressureEntries(
        range: HeartTimeRange,
        referenceDate: Date
    ) async -> [BloodPressureEntry] {
        guard
            let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
            let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)
        else {
            return []
        }

        let calendar = Calendar.current
        let interval: DateInterval

        switch range {
        case .day:
            interval = calendar.dateInterval(of: .day, for: referenceDate)!

        case .week:
            interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)!

        case .month:
            interval = calendar.dateInterval(of: .month, for: referenceDate)!

        case .year:
            interval = calendar.dateInterval(of: .year, for: referenceDate)!
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end
        )

        return await withCheckedContinuation { continuation in

            let query = HKSampleQuery(
                sampleType: HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]
            ) { _, samples, _ in

                guard let correlations = samples as? [HKCorrelation] else {
                    continuation.resume(returning: [])
                    return
                }

                var raw: [BloodPressureEntry] = []

                for correlation in correlations {

                    guard
                        let systolicSample = correlation.objects(for: systolicType).first as? HKQuantitySample,
                        let diastolicSample = correlation.objects(for: diastolicType).first as? HKQuantitySample
                    else { continue }

                    let systolic = systolicSample.quantity.doubleValue(for: .millimeterOfMercury())
                    let diastolic = diastolicSample.quantity.doubleValue(for: .millimeterOfMercury())

                    raw.append(
                        BloodPressureEntry(
                            id: UUID(), date: correlation.endDate,
                            systolic: systolic,
                            diastolic: diastolic
                        )
                    )
                }

                let filtered: [BloodPressureEntry]

                switch range {

                case .day:
                    filtered = raw

                case .week, .month:
                    let grouped = Dictionary(grouping: raw) {
                        calendar.startOfDay(for: $0.date)
                    }

                    filtered = grouped.values.compactMap {
                        $0.sorted { $0.date > $1.date }.first
                    }

                case .year:
                    let grouped = Dictionary(grouping: raw) {
                        calendar.dateComponents([.year, .month], from: $0.date)
                    }

                    filtered = grouped.values.compactMap {
                        $0.sorted { $0.date > $1.date }.first
                    }
                }

                continuation.resume(returning: filtered.sorted { $0.date < $1.date })
            }

            self.healthStore.execute(query)
        }
    }
    
    private func dateInterval(
        for range: HeartTimeRange,
        date: Date
    ) -> DateInterval {

        let calendar = Calendar.current

        switch range {
        case .day:
            return calendar.dateInterval(of: .day, for: date)!
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: date)!
        case .month:
            return calendar.dateInterval(of: .month, for: date)!
        case .year:
            return calendar.dateInterval(of: .year, for: date)!
        }
    }
    
    private func countTenMinuteBlocks(
        samples: [HKQuantitySample]
    ) -> Int {

        let sorted = samples.sorted { $0.startDate < $1.startDate }

        var count = 0
        var blockStart: Date?

        for sample in sorted {
            if blockStart == nil {
                blockStart = sample.startDate
            }

            if let start = blockStart,
               sample.startDate.timeIntervalSince(start) >= 600 {
                count += 1
                blockStart = nil
            }
        }

        return count
    }
    
    private func fetchSamples<T: HKSample>(
        type: HKSampleType,
        predicate: NSPredicate
    ) async -> [T] {

        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: true
                    )
                ]
            ) { _, samples, _ in
                continuation.resume(
                    returning: samples as? [T] ?? []
                )
            }

            healthStore.execute(query)
        }
    }
    
     func fetchQuantitySamples(
        type: HKQuantityType,
        start: Date,
        end: Date
    ) async -> [HKQuantitySample] {

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: true
                    )
                ]
            ) { _, samples, _ in
                continuation.resume(
                    returning: samples as? [HKQuantitySample] ?? []
                )
            }

            healthStore.execute(query)
        }
    }
    
     var irregularRhythmType: HKCategoryType? {
        HKCategoryType.categoryType(
            forIdentifier: .irregularHeartRhythmEvent
        )
    }
    
     func fetchHeartRateSamples(
        start: Date,
        end: Date
    ) async -> [HKQuantitySample] {

        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: true
                    )
                ]
            ) { _, samples, _ in
                continuation.resume(
                    returning: samples as? [HKQuantitySample] ?? []
                )
            }

            healthStore.execute(query)
        }
    }
    
    
     func fetchStepSamples(
        start: Date,
        end: Date
    ) async -> [HKQuantitySample] {

        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                continuation.resume(
                    returning: samples as? [HKQuantitySample] ?? []
                )
            }

            healthStore.execute(query)
        }
    }
    
    private func isResting(
        at date: Date,
        stepSamples: [HKQuantitySample]
    ) -> Bool {

        let windowStart = date.addingTimeInterval(-300) // 5 dk
        let windowEnd = date.addingTimeInterval(300)

        let steps = stepSamples.filter {
            $0.startDate >= windowStart &&
            $0.endDate <= windowEnd
        }

        let totalSteps = steps.reduce(0) {
            $0 + $1.quantity.doubleValue(for: .count())
        }

        return totalSteps < 10
    }
    
    
   
    
    
    func fetchHighHeartRateEvents(
        threshold: Int,
        range: NotificationTimeRange
    ) async -> Int {

        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        let startDate = range.startDate
        let endDate = Date()

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate
        )

        let heartRates: [HKQuantitySample] = await fetchSamples(
            type: hrType,
            predicate: predicate
        )

        let steps: [HKQuantitySample] = await fetchSamples(
            type: stepType,
            predicate: predicate
        )

        // 1️⃣ Hareketsiz zamanları bul
        let inactiveIntervals = steps
            .filter {
                $0.quantity.doubleValue(for: .count()) < 5
            }
            .map { $0.startDate ... $0.endDate }

        // 2️⃣ HR threshold üstü
        let highHR = heartRates.filter {
            $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            >= Double(threshold)
        }

        // 3️⃣ HR + hareketsiz çakışma
        let validHR = highHR.filter { hr in
            inactiveIntervals.contains { interval in
                interval.contains(hr.startDate)
            }
        }

        // 4️⃣ 10 dakikalık blok say
        return countTenMinuteBlocks(samples: validHR)
    }
    
    
    
    
    
    private func fetchSleepSamples(
        start: Date,
        end: Date
    ) async -> [HKCategorySample] {

        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, _ in
                continuation.resume(
                    returning: results as? [HKCategorySample] ?? []
                )
            }

            healthStore.execute(query)
        }
    }
    

    
    private func isDateInSleep(
        _ date: Date,
        sleepSamples: [HKCategorySample]
    ) -> Bool {

        for sample in sleepSamples {
            if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
               sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
               sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
               sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {

                if date >= sample.startDate && date <= sample.endDate {
                    return true
                }
            }
        }

        return false
    }
    
    // MARK: - Generic Category Fetch (Olayları Çekmek İçin)
        
        func fetchCategoryCount(
            identifier: HKCategoryTypeIdentifier,
            startDate: Date
        ) async -> Int {
            guard let type = HKCategoryType.categoryType(forIdentifier: identifier) else { return 0 }
            
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: Date() // Şu an
            )
            
            return await withCheckedContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: type,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: nil
                ) { _, samples, error in
                    
                    if let error = error {
                        print("❌ Fetch error for \(identifier.rawValue): \(error.localizedDescription)")
                        continuation.resume(returning: 0)
                        return
                    }
                    
                    // Olay sayısını döndür
                    continuation.resume(returning: samples?.count ?? 0)
                }
                healthStore.execute(query)
            }
        }
    
    
}
private func hkTypeAndUnit(for type: MeasurementType) -> (HKQuantityType, HKUnit)? {
    switch type {
    case .weight:
        return (HKQuantityType.quantityType(forIdentifier: .bodyMass)!, HKUnit.gramUnit(with: .kilo))
    case .height:
        return (HKQuantityType.quantityType(forIdentifier: .height)!, HKUnit.meterUnit(with: .centi))
    case .bodyFatPercentage:
        return (HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!, HKUnit.percent())
    case .leanBodyMass:
        return (HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!, HKUnit.gramUnit(with: .kilo))
    case .waistCircumference:
        return (HKQuantityType.quantityType(forIdentifier: .waistCircumference)!, HKUnit.meterUnit(with: .centi))
    case .bodyTemperature:
        return (HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!, HKUnit.degreeCelsius())
    case .basalBodyTemperature:
        return (HKQuantityType.quantityType(forIdentifier: .basalBodyTemperature)!, HKUnit.degreeCelsius())
    case .wristTemperature:
        return (HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature)!, HKUnit.degreeCelsius())
    case .bodyMassIndex:
        return (HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!, HKUnit.count())
    }
}
actor LocationsAccumulator {
    private var storage: [CLLocation] = []
    func add(_ new: [CLLocation]) {
        storage.append(contentsOf: new)
    }
    func all() -> [CLLocation] { storage }
}
extension HKWorkout: @retroactive Identifiable {
    public var id: UUID { uuid }
}
extension HKQuantityTypeIdentifier {
    public var type: HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: self)!
    }
}

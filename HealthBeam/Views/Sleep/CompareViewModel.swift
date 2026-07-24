import Foundation
import SwiftUI
import Combine
import HealthKit

enum HealthMetric: String, CaseIterable, Identifiable, Hashable {
    case sleepDuration = "Total Sleep Duration"
    case timeInBed = "Time in Bed"
    case sleepScore = "Sleep Score"
    case sleepEfficiency = "Sleep Efficiency"
    case awakeningCount = "Number of Awakenings"
    case deepSleep = "Deep Sleep"
    case remSleep = "REM Sleep"
    case lightSleep = "Light Sleep"
    case heartRateAverage = "Average Heart Rate"
    case heartRateLowest = "Lowest Heart Rate"
    case hrv = "Heart Rate Variability (HRV)"
    case respiratoryRate = "Respiratory Rate"

    var id: Self { self }

    var localizedTitle: String {
        String(localized: LocalizedStringResource(stringLiteral: rawValue))
    }

    var color: Color {
        switch self {
        case .sleepDuration, .timeInBed: return .cyan
        case .sleepScore, .sleepEfficiency: return .purple
        case .awakeningCount: return .orange
        case .deepSleep: return .indigo
        case .remSleep, .lightSleep: return .pink
        case .heartRateAverage, .heartRateLowest: return .red
        case .hrv: return .yellow
        case .respiratoryRate: return .green
        }
    }

    static let localizationSeed: [LocalizedStringResource] = [
        "Total Sleep Duration",
        "Time in Bed",
        "Sleep Score",
        "Sleep Efficiency",
        "Number of Awakenings",
        "Deep Sleep",
        "REM Sleep",
        "Light Sleep",
        "Average Heart Rate",
        "Lowest Heart Rate",
        "Heart Rate Variability (HRV)",
        "Respiratory Rate"
    ]
}
@MainActor
class CompareViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var selectedMetric1: HealthMetric = .sleepDuration
    @Published var selectedMetric2: HealthMetric = .sleepScore
    @Published var chartData1: [ChartDataPoint] = []
    @Published var chartData2: [ChartDataPoint] = []
    @Published var dateRangeString: String = ""

    private let healthKitManager = HealthKitManager.shared
    private var allSleepAnalyses: [DailySleepAnalysis] = []
    private var allHrvSamples: [HKQuantitySample] = []
    private var allRespiratorySamples: [HKQuantitySample] = []
    private var allHeartRateSamples: [HKQuantitySample] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        $selectedMetric1.combineLatest($selectedMetric2)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in self?.processChartData() }
            .store(in: &cancellables)
    }

    func fetchData() async {
        isLoading = true
        defer { isLoading = false }

        let endDate = Date()
        // DÜZELTME: Compare ekranı için de 30 gün sınırını kaldırıp 10 yıl yaptık.
        guard let startDate = Calendar.current.date(byAdding: .year, value: -10, to: endDate) else { return }
        
        // fetchLast30DaysSleep yerine fetchAllSleepData kullanıyoruz
        async let sleepTask = healthKitManager.fetchAllSleepData()
        async let hrvTask = healthKitManager.fetchHRV(startDate: startDate, endDate: endDate)
        async let respTask = healthKitManager.fetchRespiratoryRate(startDate: startDate, endDate: endDate)
        async let hrTask = healthKitManager.fetchHeartRateDuring(startDate: startDate, endDate: endDate)
        
        self.allSleepAnalyses = await sleepTask
        self.allHrvSamples = await hrvTask
        self.allRespiratorySamples = await respTask
        self.allHeartRateSamples = await hrTask
        
        processChartData()
        updateDateRangeString()
    }
    
    private func processChartData() {
        self.chartData1 = generateData(for: selectedMetric1)
        self.chartData2 = generateData(for: selectedMetric2)
    }

    private func generateData(for metric: HealthMetric) -> [ChartDataPoint] {
        let recentAnalyses = Array(allSleepAnalyses.prefix(7))
        switch metric {
        case .sleepDuration:
            return recentAnalyses.map { analysis in
                ChartDataPoint(
                    date: analysis.date,
                    value: analysis.totalAsleepTime,
                    totalSleepDurationMinutes: analysis.totalAsleepTime / 60,
                    timeInBedMinutes: analysis.totalInBedTime / 60,
                    lightSleepDurationMinutes: analysis.duration(of: .light) / 60
                )
            }
        case .sleepScore:
            return recentAnalyses.map { analysis in
                ChartDataPoint(
                    date: analysis.date,
                    value: Double(analysis.sleepScore),
                    totalSleepDurationMinutes: analysis.totalAsleepTime / 60,
                    timeInBedMinutes: analysis.totalInBedTime / 60,
                    lightSleepDurationMinutes: analysis.duration(of: .light) / 60
                )
            }
        case .deepSleep:
            return recentAnalyses.map { analysis in
                ChartDataPoint(
                    date: analysis.date,
                    value: analysis.duration(of: .deep),
                    totalSleepDurationMinutes: analysis.totalAsleepTime / 60,
                    timeInBedMinutes: analysis.totalInBedTime / 60,
                    lightSleepDurationMinutes: analysis.duration(of: .light) / 60
                )
            }
        case .heartRateAverage:
            return calculateAverage(from: allHeartRateSamples, for: recentAnalyses, unit: .count().unitDivided(by: .minute()))
        case .heartRateLowest:
            return calculateLowest(from: allHeartRateSamples, for: recentAnalyses, unit: .count().unitDivided(by: .minute()))
        case .hrv:
            return calculateAverage(from: allHrvSamples, for: recentAnalyses, unit: .secondUnit(with: .milli))
        case .respiratoryRate:
            return calculateAverage(from: allRespiratorySamples, for: recentAnalyses, unit: HKUnit(from: "count/min"))
        default:
            return recentAnalyses.map { analysis in
                ChartDataPoint(
                    date: analysis.date,
                    value: analysis.totalAsleepTime,
                    totalSleepDurationMinutes: analysis.totalAsleepTime / 60,
                    timeInBedMinutes: analysis.totalInBedTime / 60,
                    lightSleepDurationMinutes: analysis.duration(of: .light) / 60)
            }
        }
    }

    private func updateDateRangeString() {
        guard let firstDate = allSleepAnalyses.prefix(7).last?.date,
              let lastDate = allSleepAnalyses.prefix(7).first?.date else {
            self.dateRangeString = "No Data"
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        self.dateRangeString = "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
    }

    private func calculateAverage(from samples: [HKQuantitySample], for analyses: [DailySleepAnalysis], unit: HKUnit) -> [ChartDataPoint] {
        return analyses.map { analysis -> ChartDataPoint in
            guard let interval = analysis.dateInterval else {
                return ChartDataPoint(
                    date: analysis.date,
                    value: 0,
                    totalSleepDurationMinutes: analysis.totalAsleepTime / 60,
                    timeInBedMinutes: analysis.totalInBedTime / 60,
                    lightSleepDurationMinutes: analysis.duration(of: .light) / 60
                )
            }
            let relevantSamples = samples.filter { interval.contains($0.startDate) }
            guard !relevantSamples.isEmpty else {
                return ChartDataPoint(
                    date: analysis.date,
                    value: 0,
                    totalSleepDurationMinutes: analysis.totalAsleepTime / 60,
                    timeInBedMinutes: analysis.totalInBedTime / 60,
                    lightSleepDurationMinutes: analysis.duration(of: .light) / 60
                )
            }
            let totalValue = relevantSamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: unit) }
            let averageValue = totalValue / Double(relevantSamples.count)
            return ChartDataPoint(
                date: analysis.date,
                value: averageValue,
                totalSleepDurationMinutes: analysis.totalAsleepTime / 60,
                timeInBedMinutes: analysis.totalInBedTime / 60,
                lightSleepDurationMinutes: analysis.duration(of: .light) / 60
            )
        }
    }

    private func calculateLowest(from samples: [HKQuantitySample], for analyses: [DailySleepAnalysis], unit: HKUnit) -> [ChartDataPoint] {
        return analyses.map { analysis -> ChartDataPoint in
            guard let interval = analysis.dateInterval else {
                return ChartDataPoint(
                    date: analysis.date,
                    value: 0,
                    totalSleepDurationMinutes: analysis.totalAsleepTime / 60,
                    timeInBedMinutes: analysis.totalInBedTime / 60,
                    lightSleepDurationMinutes: analysis.duration(of: .light) / 60
                )
            }
            let relevantSamples = samples.filter { interval.contains($0.startDate) }
            guard let minSample = relevantSamples.min(by: { $0.quantity.doubleValue(for: unit) < $1.quantity.doubleValue(for: unit) }) else {
                return ChartDataPoint(
                    date: analysis.date,
                    value: 0,
                    totalSleepDurationMinutes: analysis.totalAsleepTime / 60,
                    timeInBedMinutes: analysis.totalInBedTime / 60,
                    lightSleepDurationMinutes: analysis.duration(of: .light) / 60
                )
            }
            return ChartDataPoint(
                date: analysis.date,
                value: minSample.quantity.doubleValue(for: unit),
                totalSleepDurationMinutes: analysis.totalAsleepTime / 60,
                timeInBedMinutes: analysis.totalInBedTime / 60,
                lightSleepDurationMinutes: analysis.duration(of: .light) / 60
            )
        }
    }
}

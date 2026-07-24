import Foundation
import Combine
import SwiftUI
import HealthKit

enum HealthDataType: String, CaseIterable, Identifiable, Hashable {
    case sleepDuration = "Total Sleep Duration"
    case timeInBed = "Time in Bed"
    case sleepScore = "Sleep Score"
    case sleepEfficiency = "Sleep Efficiency"
    case awakeningCount = "Awakening Count"
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
        "Awakening Count",
        "Deep Sleep",
        "REM Sleep",
        "Light Sleep",
        "Average Heart Rate",
        "Lowest Heart Rate",
        "Heart Rate Variability (HRV)",
        "Respiratory Rate"
    ]
}
struct MetricDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}

@MainActor
class SleepViewModel: ObservableObject {

    private var achievementsViewModel: AchievementsViewModel?

    @Published var isLoading: Bool = false
    @Published var isLoadingExtendedMetrics: Bool = false
    @Published var lastNight: DailySleepAnalysis?
    @Published var weeklyChartData: [DailySleepAnalysis] = []
    @Published var selectedAnalysisForSheet: DailySleepAnalysis?
    @Published private(set) var weekOffset: Int = 0
    @Published var selectedMetric1: HealthDataType = .sleepDuration
    @Published var selectedMetric2: HealthDataType = .heartRateAverage
    @Published var chartData1: [MetricDataPoint] = []
    @Published var chartData2: [MetricDataPoint] = []
    @Published var comparisonDateRangeString: String = ""
    @Published var comparisonWeekOffset: Int = 0
    @Published var isAtCurrentComparisonWeek: Bool = true
    @Published var trendChartData: [MetricDataPoint] = []
    @Published var trendChartDateRangeString: String = ""
    @Published var isPreviousTrendButtonDisabled: Bool = true
    @Published var isNextTrendButtonDisabled: Bool = true
    @Published var monthlyTrendChartData: [MetricDataPoint] = []
    @Published var monthlyTrendChartDateRangeString: String = ""
    @Published var isPreviousMonthTrendButtonDisabled: Bool = true
    @Published var isNextMonthTrendButtonDisabled: Bool = true
    @Published var yearlyTrendChartData: [MetricDataPoint] = []
    @Published var yearlyTrendChartDateRangeString: String = ""
    @Published var isPreviousYearTrendButtonDisabled: Bool = true
    @Published var isNextYearTrendButtonDisabled: Bool = true
    
    var weekDateRangeString: String {
        guard let firstDay = weeklyChartData.first?.date,
              let lastDay = weeklyChartData.last?.date else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: firstDay)) - \(formatter.string(from: lastDay))"
    }

    private let healthKitManager = HealthKitManager.shared
    private var allSleepAnalyses: [DailySleepAnalysis] = []
    private var allHeartRateSamples: [HKQuantitySample] = []
    private var allHrvSamples: [HKQuantitySample] = []
    private var allRespiratorySamples: [HKQuantitySample] = []
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedCoreData = false
    private var extendedLoadTask: Task<Void, Never>?

    init(achievementsViewModel: AchievementsViewModel? = nil) {
        self.achievementsViewModel = achievementsViewModel
        
        $selectedMetric1.combineLatest($selectedMetric2)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.processComparisonChartData()
            }
            .store(in: &cancellables)
    }

    deinit {
        extendedLoadTask?.cancel()
    }

    func fetchDataIfNeeded() async {
        guard !hasLoadedCoreData else { return }
        await fetchData()
    }

    func fetchData() async {
        guard !hasLoadedCoreData else { return }
        isLoading = true
        defer { isLoading = false }

        // MARK: - Demo Mode Check
        if AppReviewManager.shared.isDemoMode {
            print("💤 Sleep Demo Mode Activated")
            // MockSleep'den 365 günlük veri çek
            // Awakening count vb. artık burada oluşuyor
            self.allSleepAnalyses = MockSleep.generateMockHistory()

            processPrimaryData()
            hasLoadedCoreData = true
            isLoadingExtendedMetrics = true
            extendedLoadTask = Task { @MainActor [weak self] in
                guard let self else { return }
                self.processExtendedData()
                self.isLoadingExtendedMetrics = false
            }
            return
        }

        // --- Real Data Logic ---
        let endDate = Date()
        self.allSleepAnalyses = await healthKitManager.fetchAllSleepData(yearsBack: 2)
        processPrimaryData()
        hasLoadedCoreData = true

        guard let vitalsStartDate = Calendar.current.date(byAdding: .year, value: -2, to: endDate) else { return }

        isLoadingExtendedMetrics = true
        extendedLoadTask = Task { [weak self] in
            guard let self else { return }

            async let hrTask = self.healthKitManager.fetchHeartRateDuring(startDate: vitalsStartDate, endDate: endDate)
            async let hrvTask = self.healthKitManager.fetchHRV(startDate: vitalsStartDate, endDate: endDate)
            async let respTask = self.healthKitManager.fetchRespiratoryRate(startDate: vitalsStartDate, endDate: endDate)

            let heartRateSamples = await hrTask
            let hrvSamples = await hrvTask
            let respiratorySamples = await respTask

            await MainActor.run {
                self.allHeartRateSamples = heartRateSamples
                self.allHrvSamples = hrvSamples
                self.allRespiratorySamples = respiratorySamples
                self.processExtendedData()
                self.isLoadingExtendedMetrics = false
            }
        }
    }
    
    private func processPrimaryData() {
        self.lastNight = allSleepAnalyses.sorted(by: { $0.date > $1.date }).first

        self.weekOffset = 0
        processWeeklyChartData()
    }

    private func processExtendedData() {
        self.comparisonWeekOffset = 0
        processComparisonChartData()

        processTrendData(for: 0, metric: .sleepScore)
        processMonthlyTrendData(for: 0, metric: .sleepScore)
        processYearlyTrendData(for: 0, metric: .sleepScore)
    }

    func showPreviousWeek() {
        weekOffset -= 1
        processWeeklyChartData()
    }

    func showNextWeek() {
        guard weekOffset < 0 else { return }
        weekOffset += 1
        processWeeklyChartData()
    }

    private func processWeeklyChartData() {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        guard let targetDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date()),
              let weekInterval = calendar.dateInterval(of: .weekOfYear, for: targetDate) else {
            return
        }
        var newChartData: [DailySleepAnalysis] = []
        for dayOffset in 0..<7 {
            guard let dateForDay = calendar.date(byAdding: .day, value: dayOffset, to: weekInterval.start) else { continue }
            if let sleepDataForDay = allSleepAnalyses.first(where: { calendar.isDate($0.date, inSameDayAs: dateForDay) }) {
                newChartData.append(sleepDataForDay)
            } else {
                newChartData.append(DailySleepAnalysis(emptyFor: dateForDay))
            }
        }
        self.weeklyChartData = newChartData
    }

    func showPreviousComparisonWeek() {
        comparisonWeekOffset -= 1
        processComparisonChartData()
    }

    func showNextComparisonWeek() {
        guard comparisonWeekOffset < 0 else { return }
        comparisonWeekOffset += 1
        processComparisonChartData()
    }

    private func processComparisonChartData() {
        self.chartData1 = generateComparisonData(for: selectedMetric1, weekOffset: comparisonWeekOffset)
        self.chartData2 = generateComparisonData(for: selectedMetric2, weekOffset: comparisonWeekOffset)
        updateComparisonDateRangeString()
        self.isAtCurrentComparisonWeek = (comparisonWeekOffset == 0)
    }

    private func updateComparisonDateRangeString() {
        let calendar = Calendar.current
        var cal = calendar
        cal.firstWeekday = 2
        guard let targetDate = cal.date(byAdding: .weekOfYear, value: comparisonWeekOffset, to: Date()),
              let weekInterval = cal.dateInterval(of: .weekOfYear, for: targetDate) else {
            self.comparisonDateRangeString = ""
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let startDate = weekInterval.start
        guard let endDate = cal.date(byAdding: .day, value: 6, to: startDate) else {
            self.comparisonDateRangeString = ""
            return
        }
        self.comparisonDateRangeString = "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    // MARK: - GENERATE COMPARISON DATA (FIXED)
    private func generateComparisonData(for metric: HealthDataType, weekOffset: Int) -> [MetricDataPoint] {
        let calendar = Calendar.current
        var cal = calendar
        cal.firstWeekday = 2
        guard let targetDate = cal.date(byAdding: .weekOfYear, value: weekOffset, to: Date()),
              let weekInterval = cal.dateInterval(of: .weekOfYear, for: targetDate) else {
            return []
        }

        var weekDates: [Date] = []
        for dayOffset in 0..<7 {
            if let date = cal.date(byAdding: .day, value: dayOffset, to: weekInterval.start) {
                weekDates.append(date)
            }
        }

        // ÖNCE VITAL VERİLERİ (Nabız, HRV vb.) KONTROL ET
        // Çünkü bu veriler SleepAnalysis nesnesinde yoktur, dışarıdan gelir.
        switch metric {
        case .heartRateAverage, .heartRateLowest, .hrv, .respiratoryRate:
            if AppReviewManager.shared.isDemoMode {
                // Demo modunda bu veriler için MockVitalData kullanıyoruz
                let mockData = MockSleep.generateMockVitalData(for: metric, days: 365)
                return mockData.filter { weekInterval.contains($0.date) }
            } else {
                // Gerçek modda HealthKit verilerini hesapla
                // Bu veriler için 'analysesForWeek' e ihtiyacımız var (Uyku aralığını bulmak için)
                let analysesForWeek: [DailySleepAnalysis] = weekDates.map { date in
                    if let analysis = allSleepAnalyses.first(where: { cal.isDate($0.date, inSameDayAs: date) }) {
                        return analysis
                    } else {
                        return DailySleepAnalysis(emptyFor: date)
                    }
                }
                
                if metric == .heartRateAverage {
                     return calculateAverage(from: allHeartRateSamples, for: analysesForWeek, unit: .count().unitDivided(by: .minute()))
                } else if metric == .heartRateLowest {
                    return calculateLowest(from: allHeartRateSamples, for: analysesForWeek, unit: .count().unitDivided(by: .minute()))
                } else if metric == .hrv {
                    return calculateAverage(from: allHrvSamples, for: analysesForWeek, unit: .secondUnit(with: .milli))
                } else { // Respiratory
                    return calculateAverage(from: allRespiratorySamples, for: analysesForWeek, unit: HKUnit(from: "count/min"))
                }
            }
            
        default:
            // UYKU METRİKLERİ (Duration, Score, Phases, AWAKENING COUNT)
            // Bu veriler zaten 'allSleepAnalyses' içinde var (Mock modda da, Gerçek modda da)
            // O yüzden burası ortak çalışır.
            let analysesForWeek: [DailySleepAnalysis] = weekDates.map { date in
                if let analysis = allSleepAnalyses.first(where: { cal.isDate($0.date, inSameDayAs: date) }) {
                    return analysis
                } else {
                    return DailySleepAnalysis(emptyFor: date)
                }
            }
            
            return analysesForWeek.map { analysis in
                let pointValue = value(for: metric, from: analysis)
                return MetricDataPoint(date: analysis.date, value: pointValue)
            }
        }
    }

    private func calculateAverage(from samples: [HKQuantitySample], for analyses: [DailySleepAnalysis], unit: HKUnit) -> [MetricDataPoint] {
        return analyses.map { analysis -> MetricDataPoint in
            guard let sleepInterval = analysis.dateInterval else {
                return MetricDataPoint(date: analysis.date, value: 0)
            }
            let relevantSamples = samples.filter { sleepInterval.contains($0.startDate) }
            guard !relevantSamples.isEmpty else { return MetricDataPoint(date: analysis.date, value: 0) }
            let totalValue = relevantSamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: unit) }
            let averageValue = totalValue / Double(relevantSamples.count)
            return MetricDataPoint(date: analysis.date, value: averageValue)
        }
    }

    private func calculateLowest(from samples: [HKQuantitySample], for analyses: [DailySleepAnalysis], unit: HKUnit) -> [MetricDataPoint] {
        return analyses.map { analysis -> MetricDataPoint in
            guard let sleepInterval = analysis.dateInterval else {
                return MetricDataPoint(date: analysis.date, value: 0)
            }
            let relevantSamples = samples.filter { sleepInterval.contains($0.startDate) }
            guard let minSample = relevantSamples.min(by: { $0.quantity.doubleValue(for: unit) < $1.quantity.doubleValue(for: unit) }) else {
                return MetricDataPoint(date: analysis.date, value: 0)
            }
            return MetricDataPoint(date: analysis.date, value: minSample.quantity.doubleValue(for: unit))
        }
    }

    private func value(for metric: HealthDataType, from analysis: DailySleepAnalysis) -> Double {
        switch metric {
            case .sleepDuration: return analysis.totalAsleepTime
            case .timeInBed: return analysis.totalInBedTime
            case .sleepScore: return Double(analysis.sleepScore)
            case .sleepEfficiency: return analysis.sleepEfficiency * 100
            // Awakening Count artık düzgün çalışacak çünkü MockSleep içinde .awake periodları ürettik
            case .awakeningCount: return Double(analysis.stagePeriods.filter { $0.type == .awake }.count)
            case .deepSleep: return analysis.duration(of: .deep)
            case .remSleep: return analysis.duration(of: .rem)
            case .lightSleep: return analysis.duration(of: .light)
            default: return 0
        }
    }

    func processTrendData(for offset: Int, metric: HealthDataType) {
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: allSleepAnalyses) { calendar.dateInterval(of: .weekOfYear, for: $0.date)!.start }
        let sortedWeekStarts = groupedByWeek.keys.sorted(by: >)
        guard !sortedWeekStarts.isEmpty else { return }
        let currentWeekIndex = max(0, min(sortedWeekStarts.count - 1, offset))
        let currentWeekStart = sortedWeekStarts[currentWeekIndex]
        var weekDates: [Date] = []
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart) {
                weekDates.append(date)
            }
        }
        self.trendChartData = weekDates.map { date in
            let pointValue = allSleepAnalyses.first { calendar.isDate($0.date, inSameDayAs: date) }
                .map { value(for: metric, from: $0) } ?? 0
            return MetricDataPoint(date: date, value: pointValue)
        }
        if let first = weekDates.first, let last = weekDates.last {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            self.trendChartDateRangeString = "\(formatter.string(from: first)) - \(formatter.string(from: last))"
        }
        self.isNextTrendButtonDisabled = (offset == 0)
        self.isPreviousTrendButtonDisabled = (offset >= sortedWeekStarts.count - 1)
    }

    func processMonthlyTrendData(for offset: Int, metric: HealthDataType) {
        let calendar = Calendar.current
        guard let targetMonthDate = calendar.date(byAdding: .month, value: -offset, to: Date()),
              let _ = calendar.dateInterval(of: .month, for: targetMonthDate),
              let daysCount = calendar.range(of: .day, in: .month, for: targetMonthDate)?.count else { return }
        var days: [Date] = []
        for day in 1...daysCount {
            if let date = calendar.date(from: DateComponents(year: calendar.component(.year, from: targetMonthDate), month: calendar.component(.month, from: targetMonthDate), day: day)) {
                days.append(date)
            }
        }
        self.monthlyTrendChartData = days.map { date in
            let pointValue = allSleepAnalyses.first { calendar.isDate($0.date, inSameDayAs: date) }
                .map { value(for: metric, from: $0) } ?? 0
            return MetricDataPoint(date: date, value: pointValue)
        }
        let formatter = DateFormatter(); formatter.dateFormat = "MMMM yyyy"
        self.monthlyTrendChartDateRangeString = formatter.string(from: targetMonthDate)
        self.isNextMonthTrendButtonDisabled = (offset == 0)
        if let earliestDate = allSleepAnalyses.map({$0.date}).min() {
            self.isPreviousMonthTrendButtonDisabled = targetMonthDate <= earliestDate.startOfMonth(using: calendar)
        }
    }

    func processYearlyTrendData(for offset: Int, metric: HealthDataType) {
        let calendar = Calendar.current
        guard let targetYearDate = calendar.date(byAdding: .year, value: -offset, to: Date()) else { return }
        let targetYear = calendar.component(.year, from: targetYearDate)
        var monthlyAverages: [MetricDataPoint] = []
        for month in 1...12 {
            guard let monthStartDate = calendar.date(from: DateComponents(year: targetYear, month: month, day: 1)),
                  let monthInterval = calendar.dateInterval(of: .month, for: monthStartDate) else { continue }
            let analysesForMonth = allSleepAnalyses.filter { analysis in
                monthInterval.contains(analysis.date)
            }
            let dataPoint: MetricDataPoint
            if analysesForMonth.isEmpty {
                dataPoint = MetricDataPoint(date: monthStartDate, value: 0)
            } else {
                let sumOfValues = analysesForMonth.reduce(0.0) { partialResult, analysis in
                    partialResult + value(for: metric, from: analysis)
                }
                let averageValue = sumOfValues / Double(analysesForMonth.count)
                dataPoint = MetricDataPoint(date: monthStartDate, value: averageValue)
            }
            monthlyAverages.append(dataPoint)
        }

        self.yearlyTrendChartData = monthlyAverages

        let formatter = DateFormatter(); formatter.dateFormat = "yyyy"
        self.yearlyTrendChartDateRangeString = formatter.string(from: targetYearDate)

        self.isNextYearTrendButtonDisabled = (offset == 0)
        if let earliestDate = allSleepAnalyses.map({$0.date}).min() {
            self.isPreviousYearTrendButtonDisabled = calendar.component(.year, from: targetYearDate) <= calendar.component(.year, from: earliestDate)
        }
    }
}
extension Date {
    func startOfMonth(using calendar: Calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
    }
}

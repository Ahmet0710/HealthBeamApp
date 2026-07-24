import SwiftUI
import HealthKit
import Charts
import Combine

private enum StressLevel: String {
    case low = "Low"
    case moderate = "Moderate"
    case elevated = "Elevated"
    case high = "High"

    var tint: Color {
        switch self {
        case .low: .mint
        case .moderate: .yellow
        case .elevated: .orange
        case .high: .red
        }
    }

    var gradient: [Color] {
        switch self {
        case .low: [Color.teal, Color.mint]
        case .moderate: [Color.yellow, Color.orange]
        case .elevated: [Color.orange, Color.red.opacity(0.8)]
        case .high: [Color.red, Color.pink]
        }
    }

    var coachingTitle: String {
        switch self {
        case .low:
            String(localized: "Your signals look steady.", comment: "Stress screen summary headline for low stress.")
        case .moderate:
            String(localized: "Your body is asking for a little recovery.", comment: "Stress screen summary headline for moderate stress.")
        case .elevated:
            String(localized: "Stress is running above your usual pattern.", comment: "Stress screen summary headline for elevated stress.")
        case .high:
            String(localized: "Your recent signals suggest significant strain.", comment: "Stress screen summary headline for high stress.")
        }
    }
}

private typealias StressDriverKind = HealthSignalDriverKind

private struct StressDailySnapshot: Identifiable {
    let date: Date
    let score: Double
    let level: StressLevel
    let hrv: Double?
    let restingHeartRate: Double?
    let respiratoryRate: Double?
    let sleepHours: Double?
    let workoutMinutes: Double
    let topDrivers: [StressDriverKind]
    let signalCount: Int

    var id: Date { date }
}

private struct StressBaseline {
    let hrv: Double?
    let restingHeartRate: Double?
    let respiratoryRate: Double?
    let sleepHours: Double?
    let workoutMinutes: Double?
}

private struct StressSuggestion: Identifiable {
    let title: String
    let detail: String
    let symbol: String
    let tint: Color
    let id = UUID()
}

private struct StressSignalCardModel: Identifiable {
    enum Direction {
        case lowerIsBetter
        case higherIsBetter
    }

    let title: String
    let value: String
    let baseline: String
    let insight: String
    let tint: Color
    let direction: Direction
    let id = UUID()
}

private enum StressScoringEngine {
    static func makeSnapshots(
        dates: [Date],
        hrvByDay: [Date: Double],
        restingByDay: [Date: Double],
        respiratoryByDay: [Date: Double],
        sleepByDay: [Date: Double],
        workoutByDay: [Date: Double],
        baseline: StressBaseline
    ) -> [StressDailySnapshot] {
        dates.compactMap { day in
            let hrv = hrvByDay[day]
            let resting = restingByDay[day]
            let respiratory = respiratoryByDay[day]
            let sleep = sleepByDay[day]
            let workout = workoutByDay[day] ?? 0

            let components = [
                stressComponent(kind: .hrv, value: hrv, baseline: baseline.hrv, maxPoints: 28, lowerValueIncreasesStress: true, threshold: 0.22),
                stressComponent(kind: .restingHeartRate, value: resting, baseline: baseline.restingHeartRate, maxPoints: 24, lowerValueIncreasesStress: false, threshold: 0.14),
                stressComponent(kind: .respiratoryRate, value: respiratory, baseline: baseline.respiratoryRate, maxPoints: 16, lowerValueIncreasesStress: false, threshold: 0.10),
                stressComponent(kind: .sleep, value: sleep, baseline: baseline.sleepHours, maxPoints: 22, lowerValueIncreasesStress: true, threshold: 0.18)
            ]

            let workoutComponent: (kind: StressDriverKind, points: Double)? = {
                guard let baselineWorkout = baseline.workoutMinutes, workout > 0 else { return nil }
                let delta = max(0, workout - baselineWorkout)
                let normalized = min(delta / max(baselineWorkout + 25, 40), 1)
                let points = normalized * 10
                return points > 0 ? (.workoutLoad, points) : nil
            }()

            let validComponents = components.compactMap { $0 } + (workoutComponent.map { [$0] } ?? [])
            let signalCount = [hrv, resting, respiratory, sleep].compactMap { $0 }.count
            guard signalCount > 0 else { return nil }

            let rawScore = 10 + validComponents.reduce(0) { $0 + $1.points }
            let score = min(max(rawScore, 0), 100)

            let level: StressLevel
            switch score {
            case ..<25: level = .low
            case ..<50: level = .moderate
            case ..<75: level = .elevated
            default: level = .high
            }

            let topDrivers = validComponents
                .sorted { $0.points > $1.points }
                .prefix(2)
                .map(\.kind)

            return StressDailySnapshot(
                date: day,
                score: score,
                level: level,
                hrv: hrv,
                restingHeartRate: resting,
                respiratoryRate: respiratory,
                sleepHours: sleep,
                workoutMinutes: workout,
                topDrivers: topDrivers,
                signalCount: signalCount
            )
        }
    }

    static func suggestions(for snapshot: StressDailySnapshot, baseline: StressBaseline) -> [StressSuggestion] {
        var suggestions: [StressSuggestion] = []

        for driver in snapshot.topDrivers {
            switch driver {
            case .hrv:
                suggestions.append(
                    StressSuggestion(
                        title: String(localized: "Protect recovery time", comment: "Stress suggestion title when HRV is low."),
                        detail: String(localized: "Your HRV is below your personal baseline. A short breathing or mindfulness session can help settle your system.", comment: "Stress suggestion detail when HRV is low."),
                        symbol: "wind",
                        tint: .teal
                    )
                )
            case .restingHeartRate:
                suggestions.append(
                    StressSuggestion(
                        title: String(localized: "Ease the pace today", comment: "Stress suggestion title when resting heart rate is high."),
                        detail: String(localized: "Resting heart rate is running higher than usual. Prioritize hydration, lighter effort, and a little more downtime.", comment: "Stress suggestion detail when resting heart rate is high."),
                        symbol: "heart.text.square",
                        tint: .orange
                    )
                )
            case .respiratoryRate:
                suggestions.append(
                    StressSuggestion(
                        title: String(localized: "Slow your breathing", comment: "Stress suggestion title when respiratory rate is high."),
                        detail: String(localized: "Breathing rate is elevated versus your pattern. Try a few minutes of slower exhales to bring the system down.", comment: "Stress suggestion detail when respiratory rate is high."),
                        symbol: "lungs.fill",
                        tint: .cyan
                    )
                )
            case .sleep:
                suggestions.append(
                    StressSuggestion(
                        title: String(localized: "Defend tonight's sleep window", comment: "Stress suggestion title when sleep is low."),
                        detail: String(localized: "Sleep was shorter than your normal pattern. Earlier wind-down and lower evening stimulation will matter most.", comment: "Stress suggestion detail when sleep is low."),
                        symbol: "bed.double.fill",
                        tint: .indigo
                    )
                )
            case .workoutLoad:
                suggestions.append(
                    StressSuggestion(
                        title: String(localized: "Treat today as recovery", comment: "Stress suggestion title when workout load is high."),
                        detail: String(localized: "Recent training load looks high relative to your norm. Keep activity gentle and restore before pushing again.", comment: "Stress suggestion detail when workout load is high."),
                        symbol: "figure.cooldown",
                        tint: .pink
                    )
                )
            }
        }

        if suggestions.isEmpty {
            suggestions.append(
                StressSuggestion(
                    title: String(localized: "Stay on your current rhythm", comment: "Stress suggestion title when signals are balanced."),
                    detail: String(localized: "Your Apple Watch signals are close to your usual baseline. Keep the habits that are helping you stay steady.", comment: "Stress suggestion detail when signals are balanced."),
                    symbol: "checkmark.circle.fill",
                    tint: .mint
                )
            )
        }

        return Array(suggestions.prefix(3))
    }

    static func signalCards(for snapshot: StressDailySnapshot, baseline: StressBaseline) -> [StressSignalCardModel] {
        [
            makeSignalCard(
                title: String(localized: "HRV", comment: "Stress signal card title for heart rate variability."),
                value: snapshot.hrv,
                baseline: baseline.hrv,
                format: { "\(Int($0.rounded())) ms" },
                direction: .higherIsBetter,
                tint: .yellow
            ),
            makeSignalCard(
                title: String(localized: "Resting heart", comment: "Stress signal card title for resting heart rate."),
                value: snapshot.restingHeartRate,
                baseline: baseline.restingHeartRate,
                format: { "\(Int($0.rounded())) bpm" },
                direction: .lowerIsBetter,
                tint: .orange
            ),
            makeSignalCard(
                title: String(localized: "Respiratory", comment: "Stress signal card title for respiratory rate."),
                value: snapshot.respiratoryRate,
                baseline: baseline.respiratoryRate,
                format: { String(format: "%.1f br/min", $0) },
                direction: .lowerIsBetter,
                tint: .green
            ),
            makeSignalCard(
                title: String(localized: "Sleep", comment: "Stress signal card title for sleep."),
                value: snapshot.sleepHours,
                baseline: baseline.sleepHours,
                format: { String(format: "%.1f h", $0) },
                direction: .higherIsBetter,
                tint: .indigo
            )
        ]
        .compactMap { $0 }
    }

    static func summaryText(for snapshot: StressDailySnapshot) -> String {
        guard !snapshot.topDrivers.isEmpty else {
            return String(localized: "Your recent Apple Watch signals are close to your personal pattern.", comment: "Stress summary when there are no standout stress drivers.")
        }

        let drivers = snapshot.topDrivers.map { $0.localizedTitle.lowercased() }
        if drivers.count == 1 {
            return String(
                localized: "\(snapshot.level.coachingTitle) The biggest shift is \(drivers[0]).",
                comment: "Stress summary with a single dominant stress driver."
            )
        }

        return String(
            localized: "\(snapshot.level.coachingTitle) The biggest shifts are \(drivers[0]) and \(drivers[1]).",
            comment: "Stress summary with two dominant stress drivers."
        )
    }

    private static func stressComponent(
        kind: StressDriverKind,
        value: Double?,
        baseline: Double?,
        maxPoints: Double,
        lowerValueIncreasesStress: Bool,
        threshold: Double
    ) -> (kind: StressDriverKind, points: Double)? {
        guard let value, let baseline, baseline > 0 else { return nil }

        let delta = lowerValueIncreasesStress
            ? max(0, baseline - value)
            : max(0, value - baseline)

        let normalized = min((delta / baseline) / threshold, 1)
        let points = normalized * maxPoints
        return points > 0 ? (kind, points) : nil
    }

    private static func makeSignalCard(
        title: String,
        value: Double?,
        baseline: Double?,
        format: (Double) -> String,
        direction: StressSignalCardModel.Direction,
        tint: Color
    ) -> StressSignalCardModel? {
        guard let value, let baseline else { return nil }

        let delta = value - baseline
        let relation: String
        switch direction {
        case .higherIsBetter:
            relation = delta >= 0
                ? String(localized: "Above your baseline", comment: "Stress signal card insight when a higher value is favorable and above baseline.")
                : String(localized: "Below your baseline", comment: "Stress signal card insight when a higher value is favorable and below baseline.")
        case .lowerIsBetter:
            relation = delta <= 0
                ? String(localized: "Below your baseline", comment: "Stress signal card insight when a lower value is favorable and below baseline.")
                : String(localized: "Above your baseline", comment: "Stress signal card insight when a lower value is unfavorable and above baseline.")
        }

        return StressSignalCardModel(
            title: title,
            value: format(value),
            baseline: String(
                localized: "Usual: \(format(baseline))",
                comment: "Stress signal card baseline label with the user's usual value."
            ),
            insight: relation,
            tint: tint,
            direction: direction
        )
    }
}

@MainActor
private final class StressTrackingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var snapshots: [StressDailySnapshot] = []
    @Published var baseline: StressBaseline?
    @Published var suggestions: [StressSuggestion] = []
    @Published var signalCards: [StressSignalCardModel] = []
    @Published var errorText: String?

    private let healthKitManager: HealthKitManager
    private var hasLoaded = false

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
    }

    var latestSnapshot: StressDailySnapshot? {
        snapshots.first
    }

    var trendDeltaText: String {
        guard snapshots.count >= 8 else { return String(localized: "Building your personal baseline", comment: "Stress trend subtitle while the personal baseline is still being built.") }
        let current = snapshots.prefix(7).map(\.score).reduce(0, +) / Double(min(7, snapshots.count))
        let previousSlice = snapshots.dropFirst(7).prefix(7)
        guard !previousSlice.isEmpty else { return String(localized: "Building your personal baseline", comment: "Stress trend subtitle while the personal baseline is still being built.") }
        let previous = previousSlice.map(\.score).reduce(0, +) / Double(previousSlice.count)
        let delta = current - previous
        if delta > 6 { return String(localized: "Higher than your previous week", comment: "Stress trend subtitle when the score is higher than the prior week.") }
        if delta < -6 { return String(localized: "Lower than your previous week", comment: "Stress trend subtitle when the score is lower than the prior week.") }
        return String(localized: "Close to your previous week", comment: "Stress trend subtitle when the score is similar to the prior week.")
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        if AppReviewManager.shared.isDemoMode {
            apply(bundle: HealthSignalCoreEngine.demoBundle(for: .strained))
            errorText = nil
            hasLoaded = true
            return
        }

        if !healthKitManager.isAuthorized {
            do {
                try await healthKitManager.requestAuthorization()
            } catch {
                errorText = String(localized: "Health access is required to analyze Apple Watch stress signals.", comment: "Stress screen error shown when HealthKit access is denied.")
                return
            }
        }

        let bundle = await HealthSignalCoreLoader.load(healthKitManager: healthKitManager)

        guard let _ = bundle.snapshots.first else {
            errorText = String(localized: "Not enough Apple Watch data yet. Stress tracking needs sleep and heart signals to learn your pattern.", comment: "Stress screen error shown when not enough Apple Watch data is available.")
            snapshots = []
            baseline = Self.makeBaseline(from: bundle.baseline)
            suggestions = []
            signalCards = []
            hasLoaded = true
            return
        }

        apply(bundle: bundle)
        errorText = nil
        hasLoaded = true
    }

    private func apply(bundle: HealthSignalCoreBundle) {
        let resolvedBaseline = Self.makeBaseline(from: bundle.baseline)
        let resolvedSnapshots = Self.makeSnapshots(from: bundle.snapshots)
        snapshots = resolvedSnapshots
        baseline = resolvedBaseline

        if let latest = resolvedSnapshots.first {
            suggestions = StressScoringEngine.suggestions(for: latest, baseline: resolvedBaseline)
            signalCards = StressScoringEngine.signalCards(for: latest, baseline: resolvedBaseline)
        } else {
            suggestions = []
            signalCards = []
        }
    }

    private static func makeBaseline(from baseline: HealthSignalCoreBaseline) -> StressBaseline {
        StressBaseline(
            hrv: baseline.hrv,
            restingHeartRate: baseline.restingHeartRate,
            respiratoryRate: baseline.respiratoryRate,
            sleepHours: baseline.sleepHours,
            workoutMinutes: baseline.workoutMinutes
        )
    }

    private static func makeSnapshots(from snapshots: [HealthSignalCoreSnapshot]) -> [StressDailySnapshot] {
        snapshots.map { snapshot in
            let level: StressLevel
            switch snapshot.stressScore {
            case ..<25: level = .low
            case ..<50: level = .moderate
            case ..<75: level = .elevated
            default: level = .high
            }

            return StressDailySnapshot(
                date: snapshot.date,
                score: snapshot.stressScore,
                level: level,
                hrv: snapshot.hrv,
                restingHeartRate: snapshot.restingHeartRate,
                respiratoryRate: snapshot.respiratoryRate,
                sleepHours: snapshot.sleepHours,
                workoutMinutes: snapshot.workoutMinutes,
                topDrivers: snapshot.topDrivers,
                signalCount: snapshot.signalCount
            )
        }
    }
}

struct StressTrackingView: View {
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @StateObject private var viewModel: StressTrackingViewModel

    init() {
        _viewModel = StateObject(wrappedValue: StressTrackingViewModel(healthKitManager: HealthKitManager.shared))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.28, green: 0.12, blue: 0.08), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard

                    if let latest = viewModel.latestSnapshot {
                        suggestionsCard
                        trendCard
                        signalsGrid
                        recentPatternCard(latest: latest)
                        methodologyCard
                    } else if let errorText = viewModel.errorText {
                        emptyStateCard(message: errorText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(String(localized: "Stress", comment: "Stress screen title."))
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private var heroCard: some View {
        Group {
            if viewModel.isLoading && viewModel.latestSnapshot == nil {
                VStack(alignment: .leading, spacing: 14) {
                    Text(String(localized: "Stress", comment: "Stress loading card heading."))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.74))
                    ProgressView()
                        .tint(.teal)
                    Text(String(localized: "Analyzing Apple Watch heart, breathing, sleep, and workout signals against your personal baseline.", comment: "Stress loading card description."))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }
            } else if let snapshot = viewModel.latestSnapshot {
                VStack(alignment: .leading, spacing: 16) {
                    Text(String(localized: "Stress", comment: "Stress hero card heading."))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.74))

                    HStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: snapshot.level.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 96, height: 96)

                            VStack(spacing: 2) {
                                Text("\(Int(snapshot.score.rounded()))")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(String(localized: "score", comment: "Stress score badge unit label."))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.78))
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(String(localized: String.LocalizationValue(snapshot.level.rawValue)))
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(StressScoringEngine.summaryText(for: snapshot))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.78))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(viewModel.trendDeltaText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(snapshot.level.tint)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "Stress", comment: "Stress empty hero heading."))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.74))
                    Text(String(localized: "Stress tracking uses Apple Watch signals and personal patterns to estimate when your body is under more strain.", comment: "Stress empty hero description."))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.92, green: 0.45, blue: 0.24).opacity(0.48), Color.black.opacity(0.36)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color(red: 0.92, green: 0.45, blue: 0.24).opacity(0.18), lineWidth: 1)
        )
    }

    private var suggestionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "Suggestions", comment: "Stress section title for suggestions."))
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(viewModel.suggestions) { suggestion in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: suggestion.symbol)
                        .font(.headline)
                        .foregroundStyle(suggestion.tint)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(suggestion.tint.opacity(0.18)))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(suggestion.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Stress trend", comment: "Stress section title for the trend chart."))
                .font(.headline)
                .foregroundStyle(.white)

            Chart(viewModel.snapshots.sorted { $0.date < $1.date }) { snapshot in
                AreaMark(
                    x: .value("Date", snapshot.date),
                    y: .value("Stress", snapshot.score)
                )
                .foregroundStyle(.teal.opacity(0.18))

                LineMark(
                    x: .value("Date", snapshot.date),
                    y: .value("Stress", snapshot.score)
                )
                .foregroundStyle(.teal)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                PointMark(
                    x: .value("Date", snapshot.date),
                    y: .value("Stress", snapshot.score)
                )
                .foregroundStyle(snapshot.level.tint)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .frame(height: 220)

            Text(String(localized: "Scores are personalized against your recent Apple Watch baseline rather than using a one-size-fits-all threshold.", comment: "Stress trend chart description."))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.66))
        }
        .padding(20)
        .background(cardBackground)
    }

    private var signalsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "Signals", comment: "Stress section title for signal cards."))
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.signalCards) { signal in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(signal.title)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                        Text(signal.value)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(signal.baseline)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.56))
                        Text(signal.insight)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(signal.tint)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        signal.tint.opacity(0.36),
                                        signal.tint.opacity(0.18),
                                        Color.black.opacity(0.34)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(signal.tint.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private func recentPatternCard(latest: StressDailySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "Personal pattern", comment: "Stress section title for personal pattern details."))
                .font(.headline)
                .foregroundStyle(.white)

            patternRow(
                title: String(localized: "Current level", comment: "Stress personal pattern row title for current level."),
                detail: String(localized: "\(String(localized: String.LocalizationValue(latest.level.rawValue))) stress from \(latest.signalCount) Apple Watch signals.", comment: "Stress personal pattern detail describing the current level and signal count.")
            )
            patternRow(
                title: String(localized: "Main driver", comment: "Stress personal pattern row title for the main driver."),
                detail: latest.topDrivers.first?.localizedTitle ?? String(localized: "No clear driver today.", comment: "Stress personal pattern detail when there is no clear driver.")
            )
            patternRow(
                title: String(localized: "Recent direction", comment: "Stress personal pattern row title for recent direction."),
                detail: viewModel.trendDeltaText
            )
        }
        .padding(20)
        .background(cardBackground)
    }

    private var methodologyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "How this works", comment: "Stress methodology section title."))
                .font(.headline)
                .foregroundStyle(.white)
            Text(String(localized: "Stress is inferred from Apple Watch heart rate variability, resting heart rate, respiratory rate, sleep aligned to the day you wake up, and workout load. It's a wellness estimate, not a medical diagnosis.", comment: "Stress methodology description."))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(cardBackground)
    }

    private func emptyStateCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Not enough data yet", comment: "Stress empty state title when there is insufficient data."))
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.74))
        }
        .padding(20)
        .background(cardBackground)
    }

    private func patternRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private enum StressDemoFactory {
    struct Output {
        let snapshots: [StressDailySnapshot]
        let baseline: StressBaseline
    }

    static func makeDemoSeries() -> Output {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let baseline = StressBaseline(
            hrv: 52,
            restingHeartRate: 59,
            respiratoryRate: 14.2,
            sleepHours: 7.7,
            workoutMinutes: 38
        )

        let dates = (0..<14).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }.reversed()
        var hrvByDay: [Date: Double] = [:]
        var restingByDay: [Date: Double] = [:]
        var respiratoryByDay: [Date: Double] = [:]
        var sleepByDay: [Date: Double] = [:]
        var workoutByDay: [Date: Double] = [:]

        for (index, date) in dates.enumerated() {
            let stressWave = Double(index % 6)
            hrvByDay[date] = 54 - stressWave * 3.1
            restingByDay[date] = 58 + stressWave * 1.8
            respiratoryByDay[date] = 14 + stressWave * 0.35
            sleepByDay[date] = 7.9 - stressWave * 0.28
            workoutByDay[date] = index.isMultiple(of: 3) ? 52 : 28
        }

        let snapshots = StressScoringEngine.makeSnapshots(
            dates: Array(dates),
            hrvByDay: hrvByDay,
            restingByDay: restingByDay,
            respiratoryByDay: respiratoryByDay,
            sleepByDay: sleepByDay,
            workoutByDay: workoutByDay,
            baseline: baseline
        )
        .sorted { $0.date > $1.date }

        return Output(snapshots: snapshots, baseline: baseline)
    }
}

#Preview {
    NavigationStack {
        StressTrackingView()
            .environmentObject(HealthKitManager.shared)
    }
}

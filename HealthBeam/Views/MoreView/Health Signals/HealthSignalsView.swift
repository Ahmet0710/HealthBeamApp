import SwiftUI
import HealthKit
import Charts
import Combine

private extension String {
    var localizedHealthSignalText: String {
        NSLocalizedString(self, comment: "")
    }
}

private enum HealthSignalStatus: String {
    case strong = "Strong"
    case steady = "Steady"
    case watchful = "Watchful"
    case strained = "Strained"

    var tint: Color {
        switch self {
        case .strong: .mint
        case .steady: .teal
        case .watchful: .orange
        case .strained: .red
        }
    }

    var gradient: [Color] {
        switch self {
        case .strong: [Color.mint, Color.teal]
        case .steady: [Color.teal, Color.cyan]
        case .watchful: [Color.orange, Color.yellow]
        case .strained: [Color.red, Color.pink]
        }
    }

    var headline: String {
        switch self {
        case .strong:
            String(localized: "Your system looks well recovered.", comment: "Health Signals status headline for a strong day.")
        case .steady:
            String(localized: "Your core signals are holding steady.", comment: "Health Signals status headline for a steady day.")
        case .watchful:
            String(localized: "A few signals need more attention today.", comment: "Health Signals status headline for a watchful day.")
        case .strained:
            String(localized: "Your body is showing elevated strain.", comment: "Health Signals status headline for a strained day.")
        }
    }

    var localizedTitle: String {
        switch self {
        case .strong:
            String(localized: "Strong", comment: "Health Signals status title for a strong day.")
        case .steady:
            String(localized: "Steady", comment: "Health Signals status title for a steady day.")
        case .watchful:
            String(localized: "Watchful", comment: "Health Signals status title for a watchful day.")
        case .strained:
            String(localized: "Strained", comment: "Health Signals status title for a strained day.")
        }
    }
}

private enum HealthSignalDestination: String {
    case stress = "Stress"
    case sleep = "Sleep"
    case heart = "Heart"
    case mood = "Mood"
    case mindfulness = "Mindfulness"
}

private struct HealthSignalBaseline {
    let hrv: Double?
    let restingHeartRate: Double?
    let respiratoryRate: Double?
    let sleepHours: Double?
    let workoutMinutes: Double?
}

private struct HealthSignalSnapshot: Identifiable {
    let date: Date
    let score: Double
    let status: HealthSignalStatus
    let hrv: Double?
    let restingHeartRate: Double?
    let respiratoryRate: Double?
    let sleepHours: Double?
    let workoutMinutes: Double
    let sleepScore: Double
    let recoveryScore: Double
    let strainScore: Double

    var id: Date { date }
}

private struct HealthSignalMetricCard: Identifiable {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let tint: Color
    let id = UUID()
}

private struct ActionFeedback: Identifiable {
    let title: String
    let detail: String
    let cta: String
    let symbol: String
    let tint: Color
    let destination: HealthSignalDestination
    let id = UUID()
}

private enum HealthSignalsEngine {
    static func makeSnapshots(
        dates: [Date],
        hrvByDay: [Date: Double],
        restingByDay: [Date: Double],
        respiratoryByDay: [Date: Double],
        sleepByDay: [Date: Double],
        workoutByDay: [Date: Double],
        baseline: HealthSignalBaseline
    ) -> [HealthSignalSnapshot] {
        dates.compactMap { day in
            let hrv = hrvByDay[day]
            let resting = restingByDay[day]
            let respiratory = respiratoryByDay[day]
            let sleep = sleepByDay[day]
            let workout = workoutByDay[day] ?? 0

            let sleepPenalty = penalty(
                value: sleep,
                baseline: max(baseline.sleepHours ?? 0, 7.5),
                threshold: 0.18,
                maxPenalty: 28,
                lowerIsWorse: true
            )
            let hrvPenalty = penalty(
                value: hrv,
                baseline: baseline.hrv,
                threshold: 0.22,
                maxPenalty: 24,
                lowerIsWorse: true
            )
            let restingPenalty = penalty(
                value: resting,
                baseline: baseline.restingHeartRate,
                threshold: 0.14,
                maxPenalty: 18,
                lowerIsWorse: false
            )
            let respiratoryPenalty = penalty(
                value: respiratory,
                baseline: baseline.respiratoryRate,
                threshold: 0.10,
                maxPenalty: 10,
                lowerIsWorse: false
            )
            let workoutPenalty = workoutPenalty(today: workout, baseline: baseline.workoutMinutes)

            let availableSignals = [hrv, resting, respiratory, sleep].compactMap { $0 }.count
            guard availableSignals > 0 else { return nil }

            let totalPenalty = sleepPenalty + hrvPenalty + restingPenalty + respiratoryPenalty + workoutPenalty
            let score = max(0, min(100, 100 - totalPenalty))
            let status: HealthSignalStatus
            switch score {
            case 85...: status = .strong
            case 65..<85: status = .steady
            case 45..<65: status = .watchful
            default: status = .strained
            }

            let sleepScore = max(0, min(100, 100 - sleepPenalty * 2.8))
            let recoveryScore = max(0, min(100, 100 - (hrvPenalty + restingPenalty + respiratoryPenalty) * 1.9))
            let strainScore = max(0, min(100, 100 - workoutPenalty * 5))

            return HealthSignalSnapshot(
                date: day,
                score: score,
                status: status,
                hrv: hrv,
                restingHeartRate: resting,
                respiratoryRate: respiratory,
                sleepHours: sleep,
                workoutMinutes: workout,
                sleepScore: sleepScore,
                recoveryScore: recoveryScore,
                strainScore: strainScore
            )
        }
    }

    static func metricCards(for snapshot: HealthSignalSnapshot, baseline: HealthSignalBaseline) -> [HealthSignalMetricCard] {
        [
            makeMetricCard(
                title: String(localized: "Recovery", comment: "Health Signals metric card title for recovery."),
                value: "\(Int(snapshot.recoveryScore.rounded()))",
                detail: recoveryText(for: snapshot, baseline: baseline),
                symbol: "waveform.path.ecg",
                tint: snapshot.recoveryScore >= 75 ? .mint : (snapshot.recoveryScore >= 55 ? .orange : .red)
            ),
            makeMetricCard(
                title: String(localized: "Sleep", comment: "Health Signals metric card title for sleep."),
                value: snapshot.sleepHours.map { String(format: "%.1f h", $0) } ?? String(localized: "No data", comment: "Health Signals metric value when data is unavailable."),
                detail: sleepText(for: snapshot, baseline: baseline),
                symbol: "bed.double.fill",
                tint: snapshot.sleepScore >= 75 ? .indigo : .orange
            ),
            makeMetricCard(
                title: String(localized: "Strain", comment: "Health Signals metric card title for strain."),
                value: snapshot.workoutMinutes > 0 ? "\(Int(snapshot.workoutMinutes.rounded())) min" : String(localized: "Rest day", comment: "Health Signals strain card value when no workout is logged."),
                detail: strainText(for: snapshot, baseline: baseline),
                symbol: "figure.run",
                tint: snapshot.strainScore >= 70 ? .teal : .pink
            ),
            makeMetricCard(
                title: String(localized: "Signals", comment: "Health Signals metric card title for the combined score."),
                value: "\(Int(snapshot.score.rounded()))",
                detail: snapshot.status.headline,
                symbol: "bolt.heart.fill",
                tint: snapshot.status.tint
            )
        ]
    }

    static func actions(for snapshot: HealthSignalSnapshot, baseline: HealthSignalBaseline) -> [ActionFeedback] {
        var actions: [ActionFeedback] = []

        if let sleep = snapshot.sleepHours, sleep < max(baseline.sleepHours ?? 0, 7.5) - 0.6 {
            actions.append(
                ActionFeedback(
                    title: String(localized: "Protect tonight's sleep", comment: "Health Signals action title when sleep is below baseline."),
                    detail: String(localized: "Sleep came in below your usual pattern. Make tonight a recovery night and check your sleep trends.", comment: "Health Signals action detail when sleep is below baseline."),
                    cta: String(localized: "Open Sleep", comment: "Health Signals action button to open the sleep screen."),
                    symbol: "bed.double.fill",
                    tint: .indigo,
                    destination: .sleep
                )
            )
        }

        if snapshot.recoveryScore < 68 {
            actions.append(
                ActionFeedback(
                    title: String(localized: "Lower system load", comment: "Health Signals action title when recovery signals are weak."),
                    detail: String(localized: "Recovery signals are weaker than usual. A breathing session or a lighter day will help more than pushing harder.", comment: "Health Signals action detail when recovery signals are weak."),
                    cta: String(localized: "Open Stress", comment: "Health Signals action button to open the stress screen."),
                    symbol: "wind",
                    tint: .teal,
                    destination: .stress
                )
            )
        }

        if snapshot.status == .strained || snapshot.status == .watchful {
            actions.append(
                ActionFeedback(
                    title: String(localized: "Capture how you feel", comment: "Health Signals action title encouraging a mood check-in."),
                    detail: String(localized: "Pairing the watch data with a mood check-in will make your patterns more useful over time.", comment: "Health Signals action detail encouraging a mood check-in."),
                    cta: String(localized: "Open Mood", comment: "Health Signals action button to open the mood screen."),
                    symbol: "face.smiling.inverse",
                    tint: .mint,
                    destination: .mood
                )
            )
        }

        if let resting = snapshot.restingHeartRate,
           let baselineResting = baseline.restingHeartRate,
           resting > baselineResting * 1.12 {
            actions.append(
                ActionFeedback(
                    title: String(localized: "Review heart trends", comment: "Health Signals action title when resting heart rate is elevated."),
                    detail: String(localized: "Resting heart rate is above your recent norm. Check your heart view for context before hard effort.", comment: "Health Signals action detail when resting heart rate is elevated."),
                    cta: String(localized: "Open Heart", comment: "Health Signals action button to open the heart screen."),
                    symbol: "heart.fill",
                    tint: .red,
                    destination: .heart
                )
            )
        }

        if actions.isEmpty {
            actions.append(
                ActionFeedback(
                    title: String(localized: "Keep your current rhythm", comment: "Health Signals default action title when signals are balanced."),
                    detail: String(localized: "Your sleep, recovery, and strain signals are close to your recent baseline. A short mindfulness session can help preserve that balance.", comment: "Health Signals default action detail when signals are balanced."),
                    cta: String(localized: "Open Mindfulness", comment: "Health Signals action button to open mindfulness."),
                    symbol: "apple.meditate",
                    tint: .green,
                    destination: .mindfulness
                )
            )
        }

        return Array(actions.prefix(3))
    }

    private static func penalty(
        value: Double?,
        baseline: Double?,
        threshold: Double,
        maxPenalty: Double,
        lowerIsWorse: Bool
    ) -> Double {
        guard let value, let baseline, baseline > 0 else { return 0 }
        let delta = lowerIsWorse ? max(0, baseline - value) : max(0, value - baseline)
        let normalized = min((delta / baseline) / threshold, 1)
        return normalized * maxPenalty
    }

    private static func workoutPenalty(today: Double, baseline: Double?) -> Double {
        guard today > 0 else { return 0 }
        guard let baseline, baseline > 0 else {
            return min(today / 120, 1) * 12
        }
        let normalized = min(max(0, today - baseline) / max(baseline + 20, 45), 1)
        return normalized * 12
    }

    private static func recoveryText(for snapshot: HealthSignalSnapshot, baseline: HealthSignalBaseline) -> String {
        if let hrv = snapshot.hrv, let baselineHRV = baseline.hrv, hrv < baselineHRV * 0.82 {
            return String(localized: "HRV is below your normal range", comment: "Health Signals recovery detail when HRV is low.")
        }
        if let resting = snapshot.restingHeartRate, let baselineResting = baseline.restingHeartRate, resting > baselineResting * 1.1 {
            return String(localized: "Resting heart rate is running higher", comment: "Health Signals recovery detail when resting heart rate is elevated.")
        }
        return String(localized: "Recovery markers are near baseline", comment: "Health Signals recovery detail when recovery is near baseline.")
    }

    private static func sleepText(for snapshot: HealthSignalSnapshot, baseline: HealthSignalBaseline) -> String {
        guard let sleep = snapshot.sleepHours else {
            return String(localized: "No sleep data from HealthKit", comment: "Health Signals sleep detail when no sleep data is available.")
        }
        let target = max(baseline.sleepHours ?? 0, 7.5)
        if sleep < target - 0.6 {
            return String(localized: "Below your usual sleep window", comment: "Health Signals sleep detail when sleep is below usual.")
        }
        return String(localized: "Sleep is supporting recovery", comment: "Health Signals sleep detail when sleep supports recovery.")
    }

    private static func strainText(for snapshot: HealthSignalSnapshot, baseline: HealthSignalBaseline) -> String {
        guard snapshot.workoutMinutes > 0 else {
            return String(localized: "No workout load logged today", comment: "Health Signals strain detail when no workout load is recorded.")
        }
        guard let baseline = baseline.workoutMinutes else {
            return String(localized: "Training load recorded today", comment: "Health Signals strain detail when workout load exists but there is no baseline.")
        }
        if snapshot.workoutMinutes > baseline * 1.35 {
            return String(localized: "Higher load than your recent norm", comment: "Health Signals strain detail when workout load is above baseline.")
        }
        return String(localized: "Training load is within your pattern", comment: "Health Signals strain detail when workout load is within baseline.")
    }

    private static func makeMetricCard(
        title: String,
        value: String,
        detail: String,
        symbol: String,
        tint: Color
    ) -> HealthSignalMetricCard {
        HealthSignalMetricCard(
            title: title,
            value: value,
            detail: detail,
            symbol: symbol,
            tint: tint
        )
    }
}

@MainActor
private final class HealthSignalsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var latestSnapshot: HealthSignalSnapshot?
    @Published var history: [HealthSignalSnapshot] = []
    @Published var baseline: HealthSignalBaseline?
    @Published var metricCards: [HealthSignalMetricCard] = []
    @Published var actions: [ActionFeedback] = []
    @Published var errorText: String?
    @Published var demoScenario: HealthSignalDemoScenario = .balanced

    private let healthKitManager: HealthKitManager
    private var hasLoaded = false

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
    }

    var weeklyChangeText: String {
        guard history.count >= 8 else { return String(localized: "Building your 7-day pattern", comment: "Health Signals subtitle while the weekly pattern is still being built.") }
        let current = history.prefix(7).map(\.score).reduce(0, +) / Double(min(7, history.count))
        let previousSlice = history.dropFirst(7).prefix(7)
        guard !previousSlice.isEmpty else { return String(localized: "Building your 7-day pattern", comment: "Health Signals subtitle while the weekly pattern is still being built.") }
        let previous = previousSlice.map(\.score).reduce(0, +) / Double(previousSlice.count)
        let delta = current - previous
        if delta > 5 { return String(localized: "Stronger than last week", comment: "Health Signals subtitle when the weekly score improved.") }
        if delta < -5 { return String(localized: "Lower than last week", comment: "Health Signals subtitle when the weekly score declined.") }
        return String(localized: "Close to last week", comment: "Health Signals subtitle when the weekly score is stable.") 
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        if AppReviewManager.shared.isDemoMode {
            apply(bundle: HealthSignalCoreEngine.demoBundle(for: demoScenario))
            errorText = nil
            hasLoaded = true
            return
        }

        if !healthKitManager.isAuthorized {
            do {
                try await healthKitManager.requestAuthorization()
            } catch {
                errorText = String(localized: "Health access is required to build your daily health signals.", comment: "Health Signals error shown when HealthKit access is denied.")
                return
            }
        }

        let bundle = await HealthSignalCoreLoader.load(healthKitManager: healthKitManager)

        guard let _ = bundle.snapshots.first else {
            latestSnapshot = nil
            history = []
            baseline = Self.makeBaseline(from: bundle.baseline)
            metricCards = []
            actions = []
            errorText = String(localized: "Not enough Apple Watch data yet. Health Signals needs recent sleep and heart patterns to build feedback.", comment: "Health Signals error shown when not enough Apple Watch data is available.")
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
        latestSnapshot = resolvedSnapshots.first
        history = resolvedSnapshots
        baseline = resolvedBaseline

        if let latest = resolvedSnapshots.first {
            metricCards = HealthSignalsEngine.metricCards(for: latest, baseline: resolvedBaseline)
            actions = HealthSignalsEngine.actions(for: latest, baseline: resolvedBaseline)
        } else {
            metricCards = []
            actions = []
        }
    }

    private static func makeBaseline(from baseline: HealthSignalCoreBaseline) -> HealthSignalBaseline {
        HealthSignalBaseline(
            hrv: baseline.hrv,
            restingHeartRate: baseline.restingHeartRate,
            respiratoryRate: baseline.respiratoryRate,
            sleepHours: baseline.sleepHours,
            workoutMinutes: baseline.workoutMinutes
        )
    }

    private static func makeSnapshots(from snapshots: [HealthSignalCoreSnapshot]) -> [HealthSignalSnapshot] {
        snapshots.map { snapshot in
            HealthSignalSnapshot(
                date: snapshot.date,
                score: snapshot.readinessScore,
                status: status(for: snapshot.readinessScore),
                hrv: snapshot.hrv,
                restingHeartRate: snapshot.restingHeartRate,
                respiratoryRate: snapshot.respiratoryRate,
                sleepHours: snapshot.sleepHours,
                workoutMinutes: snapshot.workoutMinutes,
                sleepScore: snapshot.sleepScore,
                recoveryScore: snapshot.recoveryScore,
                strainScore: snapshot.strainScore
            )
        }
    }

    private static func status(for score: Double) -> HealthSignalStatus {
        switch score {
        case 85...: .strong
        case 65..<85: .steady
        case 45..<65: .watchful
        default: .strained
        }
    }
}

struct HealthSignalsView: View {
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @StateObject private var viewModel: HealthSignalsViewModel

    init() {
        _viewModel = StateObject(wrappedValue: HealthSignalsViewModel(healthKitManager: HealthKitManager.shared))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.16, blue: 0.24), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard
                    if AppReviewManager.shared.isDemoMode {
                        demoScenarioPicker
                    }

                    if let latest = viewModel.latestSnapshot, let baseline = viewModel.baseline {
                        metricsSection
                        trendSection
                        actionsSection(for: latest, baseline: baseline)
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
        .navigationTitle(String(localized: "Health Signals", comment: "Health Signals screen title."))
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private var demoScenarioPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Demo scenarios")
                .font(.headline)
                .foregroundStyle(.white)

            Picker("Demo scenario", selection: Binding(
                get: { viewModel.demoScenario },
                set: { newValue in
                    viewModel.demoScenario = newValue
                    Task { await viewModel.load() }
                }
            )) {
                ForEach(HealthSignalDemoScenario.allCases) { scenario in
                    Text(scenario.localizedTitle).tag(scenario)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(18)
        .background(cardBackground)
    }

    private var heroCard: some View {
        Group {
            if viewModel.isLoading && viewModel.latestSnapshot == nil {
                VStack(alignment: .leading, spacing: 14) {
                    Text(String(localized: "Health Signals", comment: "Health Signals loading card heading."))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.74))
                    ProgressView()
                        .tint(.cyan)
                    Text(String(localized: "Combining sleep, recovery, and Apple Watch stress markers into one daily signal score.", comment: "Health Signals loading card description."))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }
            } else if let latest = viewModel.latestSnapshot {
                VStack(alignment: .leading, spacing: 16) {
                    Text(String(localized: "Health Signals", comment: "Health Signals hero card heading."))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.74))

                    HStack(alignment: .top, spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: latest.status.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 98, height: 98)

                            VStack(spacing: 2) {
                                Text("\(Int(latest.score.rounded()))")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(String(localized: "daily", comment: "Health Signals score badge unit label."))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.78))
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(latest.status.localizedTitle)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(latest.status.headline)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.78))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(viewModel.weeklyChangeText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(latest.status.tint)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "Health Signals", comment: "Health Signals empty hero heading."))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.74))
                    Text(String(localized: "A combined view of recovery, sleep, and workout load using your recent Apple Watch and HealthKit patterns.", comment: "Health Signals empty hero description."))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.42), Color.blue.opacity(0.28), Color.black.opacity(0.42)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.cyan.opacity(0.16), lineWidth: 1)
        )
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "Today", comment: "Health Signals section title for today's metrics."))
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.metricCards) { card in
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: card.symbol)
                            .foregroundStyle(card.tint)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(card.tint.opacity(0.18)))

                        Text(card.title.localizedHealthSignalText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))

                        Text(card.value)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(card.detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.66))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [card.tint.opacity(0.34), Color.black.opacity(0.55)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(card.tint.opacity(0.22), lineWidth: 1)
                    )
                }
            }
        }
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "7-day trend", comment: "Health Signals section title for the weekly trend chart."))
                .font(.headline)
                .foregroundStyle(.white)

            Chart(viewModel.history.sorted { $0.date < $1.date }) { snapshot in
                AreaMark(
                    x: .value("Date", snapshot.date),
                    y: .value("Score", snapshot.score)
                )
                .foregroundStyle(.cyan.opacity(0.18))

                LineMark(
                    x: .value("Date", snapshot.date),
                    y: .value("Score", snapshot.score)
                )
                .foregroundStyle(.cyan)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                PointMark(
                    x: .value("Date", snapshot.date),
                    y: .value("Score", snapshot.score)
                )
                .foregroundStyle(snapshot.status.tint)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .frame(height: 220)

            Text(String(localized: "The score gets stronger when sleep, recovery markers, and workout load stay close to your recent pattern.", comment: "Health Signals trend chart description."))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.66))
        }
        .padding(20)
        .background(cardBackground)
    }

    private func actionsSection(for snapshot: HealthSignalSnapshot, baseline: HealthSignalBaseline) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "Actionable feedback", comment: "Health Signals section title for recommended actions."))
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(viewModel.actions) { action in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: action.symbol)
                            .font(.headline)
                            .foregroundStyle(action.tint)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(action.tint.opacity(0.18)))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.title.localizedHealthSignalText)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(action.detail)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.68))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    NavigationLink {
                        destinationView(for: action.destination)
                    } label: {
                        HStack(spacing: 8) {
                            Text(action.cta.localizedHealthSignalText)
                                .font(.caption.weight(.semibold))
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(action.tint)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [action.tint.opacity(0.24), Color.black.opacity(0.52)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(action.tint.opacity(0.16), lineWidth: 1)
                )
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private var methodologyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Methodology", comment: "Health Signals methodology section title."))
                .font(.headline)
                .foregroundStyle(.white)
            Text(String(localized: "Health Signals blends Apple Watch heart and breathing trends, wake-day sleep, and workout load into a daily readiness-style score. It is meant for wellness feedback, not diagnosis.", comment: "Health Signals methodology description."))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(cardBackground)
    }

    private func emptyStateCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Health Signals", comment: "Health Signals empty state heading."))
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.10), Color.black.opacity(0.34)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    @ViewBuilder
    private func destinationView(for destination: HealthSignalDestination) -> some View {
        switch destination {
        case .stress:
            StressTrackingView()
        case .sleep:
            SleepView()
        case .heart:
            HeartSummaryView()
                .environmentObject(healthKitManager)
        case .mood:
            MoodTrackingView()
                .toolbar(.hidden, for: .tabBar)
        case .mindfulness:
            MindfulnessHomeView()
                .toolbar(.hidden, for: .tabBar)
        }
    }
}

#Preview {
    NavigationStack {
        HealthSignalsView()
            .environmentObject(HealthKitManager.shared)
    }
}

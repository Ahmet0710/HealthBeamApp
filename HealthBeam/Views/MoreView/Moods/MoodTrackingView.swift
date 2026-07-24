import SwiftUI
import SwiftData

private extension String {
    var localizedMoodText: String {
        NSLocalizedString(self, comment: "")
    }
}

private func localizedMoodFormat(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: NSLocalizedString(key, comment: ""), locale: Locale.current, arguments: arguments)
}

private func localizedMoodCount(_ singularKey: String, _ pluralKey: String, count: Int) -> String {
    localizedMoodFormat(count == 1 ? singularKey : pluralKey, count)
}

private extension MoodKind {
    var title: String {
        switch self {
        case .joyful: "Joyful".localizedMoodText
        case .happy: "Happy".localizedMoodText
        case .excited: "Excited".localizedMoodText
        case .relaxed: "Relaxed".localizedMoodText
        case .grateful: "Grateful".localizedMoodText
        case .thoughtful: "Thoughtful".localizedMoodText
        case .neutral: "Neutral".localizedMoodText
        case .tired: "Tired".localizedMoodText
        case .sad: "Sad".localizedMoodText
        case .angry: "Angry".localizedMoodText
        }
    }

    var emoji: String {
        switch self {
        case .joyful: "😊"
        case .happy: "🙂"
        case .excited: "🤩"
        case .relaxed: "😌"
        case .grateful: "🙏"
        case .thoughtful: "🤔"
        case .neutral: "😐"
        case .tired: "😴"
        case .sad: "😔"
        case .angry: "😠"
        }
    }

    var tint: Color {
        switch self {
        case .joyful: .yellow
        case .happy: .mint
        case .excited: .orange
        case .relaxed: .teal
        case .grateful: .green
        case .thoughtful: .indigo
        case .neutral: .gray
        case .tired: .blue
        case .sad: .cyan
        case .angry: .red
        }
    }
}

private enum MoodTimeBucket: String, CaseIterable, Identifiable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"

    var id: String { rawValue }

    var title: String { rawValue.localizedMoodText }

    init(date: Date) {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12:
            self = .morning
        case 12..<17:
            self = .afternoon
        case 17..<22:
            self = .evening
        default:
            self = .night
        }
    }
}

private struct MoodDayPoint: Identifiable {
    let date: Date
    let averageScore: Double?

    var id: Date { date }
}

private struct MoodSummary {
    let recentAverage: Double
    let previousAverage: Double?
    let dominantMood: MoodKind
    let dominantCount: Int
    let bestTimeOfDay: MoodTimeBucket?
    let loggedDays: Int
    let streak: Int
    let positiveRatio: Double
    let highestDay: MoodDayPoint?
    let lowestDay: MoodDayPoint?

    var deltaText: String {
        guard let previousAverage else { return "Building your baseline".localizedMoodText }
        let delta = recentAverage - previousAverage
        if delta > 0.25 { return "Up from last week".localizedMoodText }
        if delta < -0.25 { return "Lower than last week".localizedMoodText }
        return "Steady versus last week".localizedMoodText
    }

    var averageDescriptor: String {
        switch recentAverage {
        case 4.4...: "Very positive".localizedMoodText
        case 3.8..<4.4: "Balanced and positive".localizedMoodText
        case 3.1..<3.8: "Mostly steady".localizedMoodText
        case 2.4..<3.1: "Mixed energy".localizedMoodText
        default: "Needs extra care".localizedMoodText
        }
    }
}

private struct MoodTimeInsight: Identifiable {
    let bucket: MoodTimeBucket
    let averageScore: Double
    let count: Int

    var id: MoodTimeBucket { bucket }
}

private enum MoodScreenTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case trends = "Trends"
    case history = "History"

    var id: String { rawValue }

    var title: String { rawValue.localizedMoodText }

    var icon: String {
        switch self {
        case .overview: "sparkles"
        case .trends: "chart.xyaxis.line"
        case .history: "clock.arrow.circlepath"
        }
    }
}

private struct MoodCheckInLevel: Identifiable {
    let index: Int
    let title: String
    let subtitle: String
    let symbol: String
    let colors: [Color]
    let mood: MoodKind
    let suggestedTags: [String]

    var id: Int { index }
}

private enum MoodInsightsEngine {
    static func trendPoints(from entries: [MoodEntry], days: Int, calendar: Calendar = .current) -> [MoodDayPoint] {
        let today = calendar.startOfDay(for: Date())

        return (0..<days).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let scores = entries
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .map(\.moodKind.score)

            let average = scores.isEmpty ? nil : scores.reduce(0, +) / Double(scores.count)
            return MoodDayPoint(date: date, averageScore: average)
        }
    }

    static func summary(from entries: [MoodEntry], calendar: Calendar = .current) -> MoodSummary? {
        guard !entries.isEmpty else { return nil }

        let recentCutoff = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let previousCutoff = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()

        let recentEntries = entries.filter { $0.date >= recentCutoff }
        let comparisonEntries = entries.filter { $0.date < recentCutoff && $0.date >= previousCutoff }
        let effectiveEntries = recentEntries.isEmpty ? entries : recentEntries

        let dominantCounts = Dictionary(grouping: effectiveEntries, by: \.moodKind).mapValues(\.count)
        guard let dominantPair = dominantCounts.max(by: { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.score < rhs.key.score
            }
            return lhs.value < rhs.value
        }) else {
            return nil
        }

        let bestTimeBucket = Dictionary(grouping: effectiveEntries, by: { MoodTimeBucket(date: $0.date) })
            .mapValues { groupedEntries in
                groupedEntries.map(\.moodKind.score).reduce(0, +) / Double(groupedEntries.count)
            }
            .max(by: { $0.value < $1.value })?
            .key

        let loggedDays = Set(effectiveEntries.map { calendar.startOfDay(for: $0.date) }).count
        let positiveRatio = Double(effectiveEntries.filter { $0.moodKind.score >= 4.0 }.count) / Double(effectiveEntries.count)
        let recentAverage = effectiveEntries.map(\.moodKind.score).reduce(0, +) / Double(effectiveEntries.count)
        let previousAverage = comparisonEntries.isEmpty ? nil : comparisonEntries.map(\.moodKind.score).reduce(0, +) / Double(comparisonEntries.count)

        let recentPoints = trendPoints(from: effectiveEntries, days: 7, calendar: calendar).filter { $0.averageScore != nil }
        let highestDay = recentPoints.max(by: { ($0.averageScore ?? 0) < ($1.averageScore ?? 0) })
        let lowestDay = recentPoints.min(by: { ($0.averageScore ?? 0) < ($1.averageScore ?? 0) })

        return MoodSummary(
            recentAverage: recentAverage,
            previousAverage: previousAverage,
            dominantMood: dominantPair.key,
            dominantCount: dominantPair.value,
            bestTimeOfDay: bestTimeBucket,
            loggedDays: loggedDays,
            streak: consecutiveLoggingDays(from: entries, calendar: calendar),
            positiveRatio: positiveRatio,
            highestDay: highestDay,
            lowestDay: lowestDay
        )
    }

    static func timeInsights(from entries: [MoodEntry]) -> [MoodTimeInsight] {
        MoodTimeBucket.allCases.compactMap { bucket in
            let matchingEntries = entries.filter { MoodTimeBucket(date: $0.date) == bucket }
            guard !matchingEntries.isEmpty else { return nil }

            let average = matchingEntries.map(\.moodKind.score).reduce(0, +) / Double(matchingEntries.count)
            return MoodTimeInsight(bucket: bucket, averageScore: average, count: matchingEntries.count)
        }
        .sorted { $0.averageScore > $1.averageScore }
    }

    private static func consecutiveLoggingDays(from entries: [MoodEntry], calendar: Calendar) -> Int {
        let loggedDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var cursor = calendar.startOfDay(for: Date())

        while loggedDays.contains(cursor) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previousDay
        }

        return streak
    }
}

struct MoodTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodEntry.date, order: .reverse) private var storedMoodEntries: [MoodEntry]

    @State private var showingCheckInSheet = false
    @State private var selectedMoodEntry: MoodEntry?
    @State private var selectedTab: MoodScreenTab = .overview
    @State private var displayedMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var selectedHistoryDate = Calendar.current.startOfDay(for: Date())

    private let calendar = Calendar.current

    private var activeEntries: [MoodEntry] {
        let allEntries = AppReviewManager.shared.isDemoMode ? MockMood.sampleEntries + storedMoodEntries : storedMoodEntries
        return allEntries.sorted { $0.date > $1.date }
    }

    private var summary: MoodSummary? {
        MoodInsightsEngine.summary(from: activeEntries, calendar: calendar)
    }

    private var trendPoints: [MoodDayPoint] {
        MoodInsightsEngine.trendPoints(from: activeEntries, days: 14, calendar: calendar)
    }

    private var recentEntries: [MoodEntry] {
        Array(activeEntries.prefix(6))
    }

    private var latestEntry: MoodEntry? {
        activeEntries.first
    }

    private var todayEntries: [MoodEntry] {
        activeEntries.filter { calendar.isDateInToday($0.date) }
    }

    private var timeInsights: [MoodTimeInsight] {
        MoodInsightsEngine.timeInsights(from: activeEntries)
    }

    private var displayedMonthDays: [Date] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
            let lastDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
            let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: lastDay)
        else {
            return []
        }

        var days: [Date] = []
        var cursor = firstWeek.start
        while cursor < lastWeek.end {
            days.append(cursor)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
        }
        return days
    }

    private var entriesBySelectedDay: [MoodEntry] {
        activeEntries.filter { calendar.isDate($0.date, inSameDayAs: selectedHistoryDate) }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            tabPage {
                overviewHeader
                overviewContent
            }
            .tabItem {
                Label(MoodScreenTab.overview.title, systemImage: MoodScreenTab.overview.icon)
            }
            .tag(MoodScreenTab.overview)

            tabPage {
                trendsHeader
                trendsContent
            }
            .tabItem {
                Label(MoodScreenTab.trends.title, systemImage: MoodScreenTab.trends.icon)
            }
            .tag(MoodScreenTab.trends)

            tabPage {
                historyHeader
                historyContent
            }
            .tabItem {
                Label(MoodScreenTab.history.title, systemImage: MoodScreenTab.history.icon)
            }
            .tag(MoodScreenTab.history)
        }
        .navigationTitle("Mood".localizedMoodText)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingCheckInSheet) {
            MoodCheckInSheet { newEntry in
                if !AppReviewManager.shared.isDemoMode {
                    modelContext.insert(newEntry)
                }
            }
        }
        .sheet(item: $selectedMoodEntry) { entry in
            MoodEntryDetailSheet(entry: entry)
        }
    }

    private var backgroundGradient: some View {
        ZStack {
            Color.black

            LinearGradient(
                colors: [
                    Color.teal.opacity(0.72),
                    Color.teal.opacity(0.28),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color.teal.opacity(0.38),
                    Color.teal.opacity(0.14),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
        }
    }

    private func tabPage<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    content()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
    }

    @ViewBuilder
    private var overviewContent: some View {
        if !todayEntries.isEmpty {
            todayMoodsCard
        }

        if let latestEntry, !calendar.isDateInToday(latestEntry.date) {
            latestCheckInCard(entry: latestEntry)
        } else {
            if activeEntries.isEmpty {
                emptyStateCard
            }
        }
    }

    @ViewBuilder
    private var trendsContent: some View {
        if let summary {
            insightGrid(summary: summary)
            trendCard
            if !timeInsights.isEmpty {
                timeOfDayCard
            }
            patternCard(summary: summary)
        } else {
            emptyStateCard
        }
    }

    @ViewBuilder
    private var historyContent: some View {
        if activeEntries.isEmpty {
            emptyStateCard
        } else {
            calendarCard
            historyDayList
        }
    }

    private var overviewHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood".localizedMoodText)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            if let latestTodayEntry = todayEntries.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's status".localizedMoodText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                    HStack(spacing: 12) {
                        Text(latestTodayEntry.moodKind.emoji)
                            .font(.system(size: 34))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(localizedMoodCount("%lld mood log today", "%lld mood logs today", count: todayEntries.count))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(latestTodayEntry.tagsDisplayText)
                                .font(.subheadline)
                                .foregroundStyle(latestTodayEntry.moodKind.tint)
                                .lineLimit(2)
                        }
                    }
                }
            } else {
                Text("Log how you feel right now. Trends and charts live in the Trends tab, while the calendar history lives in History.".localizedMoodText)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
            }

            Button {
                showingCheckInSheet = true
            } label: {
                Label("Log mood".localizedMoodText, systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.mint)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.mint.opacity(0.35),
                            Color.cyan.opacity(0.22),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var trendsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Charts".localizedMoodText)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            Text("See your strongest moods, best time of day, check-in frequency, and streaks here.".localizedMoodText)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
        }
        .padding(20)
        .background(cardBackground)
    }

    private var historyHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History".localizedMoodText)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            Text("Browse your logged moods by day. Tap any date on the calendar to see every check-in you saved that day.".localizedMoodText)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
        }
        .padding(20)
        .background(cardBackground)
    }

    private var todayMoodsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Today".localizedMoodText, systemImage: "sun.max.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(localizedMoodCount("%lld check-in", "%lld check-ins", count: todayEntries.count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.64))
            }

            ForEach(todayEntries) { entry in
                Button {
                    selectedMoodEntry = entry
                } label: {
                    HStack(spacing: 14) {
                        Text(entry.moodKind.emoji)
                            .font(.system(size: 26))
                            .frame(width: 46, height: 46)
                            .background(entry.moodKind.tint.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.localizedTitle)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(entry.date.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.62))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(entry.tagsDisplayText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(entry.moodKind.tint)
                                .multilineTextAlignment(.trailing)
                                .lineLimit(2)
                            if !entry.noteText.isEmpty {
                                Text(entry.localizedNoteText)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                                    .lineLimit(1)
                            }
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.38))
                    }
                }
                .buttonStyle(.plain)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    entry.moodKind.tint.opacity(0.22),
                                    Color.black.opacity(0.28)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            (todayEntries.first?.moodKind.tint ?? .mint).opacity(0.52),
                            (todayEntries.first?.moodKind.tint ?? .mint).opacity(0.26),
                            Color.black.opacity(0.42)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke((todayEntries.first?.moodKind.tint ?? .mint).opacity(0.18), lineWidth: 1)
        )
    }

    private func latestCheckInCard(entry: MoodEntry) -> some View {
        Button {
            selectedMoodEntry = entry
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text("Latest check-in".localizedMoodText)
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 14) {
                    Text(entry.moodKind.emoji)
                        .font(.system(size: 28))
                        .frame(width: 48, height: 48)
                        .background(entry.moodKind.tint.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.localizedTitle)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.38))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(20)
        .background(cardBackground)
    }

    private func insightGrid(summary: MoodSummary) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            insightTile(
                title: "Top mood".localizedMoodText,
                value: "\(summary.dominantMood.emoji) \(summary.dominantMood.title)",
                detail: localizedMoodCount("%lld recent check-in", "%lld recent check-ins", count: summary.dominantCount),
                tint: summary.dominantMood.tint
            )

            insightTile(
                title: "Best time".localizedMoodText,
                value: summary.bestTimeOfDay?.title ?? "Learning".localizedMoodText,
                detail: "When your mood scores are highest".localizedMoodText,
                tint: .blue
            )

            insightTile(
                title: "Check-in days".localizedMoodText,
                value: "\(summary.loggedDays)",
                detail: "Days logged in the last week".localizedMoodText,
                tint: .teal
            )

            insightTile(
                title: "Current streak".localizedMoodText,
                value: localizedMoodCount("%lld day", "%lld days", count: summary.streak),
                detail: "Consecutive days with mood logs".localizedMoodText,
                tint: .orange
            )
        }
    }

    private func insightTile(title: String, value: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 112, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.42),
                            tint.opacity(0.26),
                            Color.black.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        )
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Two-week trend".localizedMoodText)
                .font(.headline)
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(trendPoints) { point in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(color(for: point.averageScore))
                            .frame(height: barHeight(for: point.averageScore))
                            .overlay(alignment: .bottom) {
                                if point.averageScore == nil {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                }
                            }

                        Text(shortDayLabel(for: point.date))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }

            Text("Higher columns reflect calmer, more positive mood check-ins. Missing days stay hollow so gaps are visible.".localizedMoodText)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(20)
        .background(cardBackground)
    }

    private var timeOfDayCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily rhythm".localizedMoodText)
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(timeInsights) { insight in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(insight.bucket.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(localizedMoodCount("%lld log", "%lld logs", count: insight.count))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                            Capsule()
                                .fill(barGradient(for: insight.averageScore))
                                .frame(width: max(24, proxy.size.width * CGFloat(insight.averageScore / 5.0)))
                        }
                    }
                    .frame(height: 10)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private func patternCard(summary: MoodSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Patterns".localizedMoodText)
                .font(.headline)
                .foregroundStyle(.white)

            patternRow(
                title: "Emotional balance".localizedMoodText,
                detail: localizedMoodFormat("%lld%% of recent check-ins were positive.", Int(summary.positiveRatio * 100))
            )

            patternRow(
                title: "Highest day".localizedMoodText,
                detail: dayText(for: summary.highestDay, fallback: "Log a few more days to identify peaks.".localizedMoodText)
            )

            patternRow(
                title: "Lowest day".localizedMoodText,
                detail: dayText(for: summary.lowestDay, fallback: "No lower-energy days detected recently.".localizedMoodText)
            )
        }
        .padding(20)
        .background(cardBackground)
    }

    private var recentCheckIns: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent check-ins".localizedMoodText)
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(recentEntries) { entry in
                HStack(spacing: 14) {
                    Button {
                        selectedMoodEntry = entry
                    } label: {
                        HStack(spacing: 14) {
                            Text(entry.moodKind.emoji)
                                .font(.system(size: 24))
                                .frame(width: 38, height: 38)
                                .background(entry.moodKind.tint.opacity(0.16))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.localizedTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.62))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 3) {
                                Text(entry.tagsDisplayText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(entry.moodKind.tint)
                                if !entry.noteText.isEmpty {
                                    Text(entry.localizedNoteText)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.5))
                                        .lineLimit(1)
                                }
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.38))
                        }
                    }
                    .buttonStyle(.plain)

                    if !AppReviewManager.shared.isDemoMode {
                        Button {
                            modelContext.delete(entry)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.red)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color.red.opacity(0.14)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .contextMenu {
                    if !AppReviewManager.shared.isDemoMode {
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                        } label: {
                            Label("Delete".localizedMoodText, systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    if let previousMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
                        displayedMonth = previousMonth
                        syncSelectedDateIfNeeded()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)

                Spacer()

                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    if let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                        displayedMonth = nextMonth
                        syncSelectedDateIfNeeded()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }

            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.54))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(displayedMonthDays, id: \.self) { day in
                    calendarDayCell(for: day)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private var historyDayList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(selectedHistoryDate.formatted(.dateTime.weekday(.wide).month().day()))
                .font(.headline)
                .foregroundStyle(.white)

            if entriesBySelectedDay.isEmpty {
                Text("No moods logged on this day.".localizedMoodText)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.64))
            } else {
                ForEach(entriesBySelectedDay) { entry in
                    HStack(spacing: 14) {
                        Button {
                            selectedMoodEntry = entry
                        } label: {
                            HStack(spacing: 14) {
                                Text(entry.moodKind.emoji)
                                    .font(.system(size: 24))
                                    .frame(width: 38, height: 38)
                                    .background(entry.moodKind.tint.opacity(0.16))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.localizedTitle)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.62))
                                }

                                Spacer()

                                Text(entry.tagsDisplayText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(entry.moodKind.tint)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.trailing)

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.38))
                            }
                        }
                        .buttonStyle(.plain)

                        if !AppReviewManager.shared.isDemoMode {
                            Button {
                                modelContext.delete(entry)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.red)
                                    .frame(width: 30, height: 30)
                                    .background(Circle().fill(Color.red.opacity(0.14)))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 6)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                    .contextMenu {
                        if !AppReviewManager.shared.isDemoMode {
                            Button(role: .destructive) {
                                modelContext.delete(entry)
                            } label: {
                                Label("Delete".localizedMoodText, systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No mood history yet".localizedMoodText)
                .font(.headline)
                .foregroundStyle(.white)
            Text("Mood tracking is now separate from Journal. Log a few moods and this screen will surface trends, streaks, and your strongest time of day.".localizedMoodText)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(20)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private func patternRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    private func shortDayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }

    private func barHeight(for score: Double?) -> CGFloat {
        guard let score else { return 42 }
        return 34 + CGFloat(score / 5.0) * 120
    }

    private func color(for score: Double?) -> Color {
        guard let score else { return Color.clear }
        switch score {
        case 4.2...:
            return .mint
        case 3.3..<4.2:
            return .teal
        case 2.4..<3.3:
            return .yellow
        default:
            return .orange
        }
    }

    private func dayText(for point: MoodDayPoint?, fallback: String) -> String {
        guard let point, let score = point.averageScore else { return fallback }
        let descriptor: String
        switch score {
        case 4.2...:
            descriptor = "strong and positive".localizedMoodText
        case 3.3..<4.2:
            descriptor = "steady".localizedMoodText
        case 2.4..<3.3:
            descriptor = "mixed".localizedMoodText
        default:
            descriptor = "lower energy".localizedMoodText
        }

        return localizedMoodFormat("%@ felt %@.", point.date.formatted(date: .abbreviated, time: .omitted), descriptor)
    }

    private func summaryBadge(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.56))
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
    }

    private func barGradient(for score: Double) -> LinearGradient {
        let color = color(for: score)
        return LinearGradient(
            colors: [color.opacity(0.8), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func calendarDayCell(for day: Date) -> some View {
        let isCurrentMonth = calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month)
        let isSelected = calendar.isDate(day, inSameDayAs: selectedHistoryDate)
        let dayEntries = activeEntries.filter { calendar.isDate($0.date, inSameDayAs: day) }
        let dayTint = dayEntries.first?.moodKind.tint ?? .white

        return Button {
            selectedHistoryDate = calendar.startOfDay(for: day)
        } label: {
            VStack(spacing: 6) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isCurrentMonth ? .white : .white.opacity(0.32))

                if !dayEntries.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(Array(dayEntries.prefix(3))) { entry in
                            Circle()
                                .fill(entry.moodKind.tint)
                                .frame(width: 6, height: 6)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? dayTint.opacity(0.28) : Color.white.opacity(isCurrentMonth ? 0.04 : 0.01))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? dayTint.opacity(0.65) : Color.white.opacity(0.04), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func syncSelectedDateIfNeeded() {
        guard calendar.isDate(selectedHistoryDate, equalTo: displayedMonth, toGranularity: .month) == false else { return }
        if let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) {
            selectedHistoryDate = firstDay
        }
    }
}

private struct MoodEntryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: MoodEntry

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Mood snapshot".localizedMoodText)
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.74))

                                Text(entry.localizedTitle)
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text(entry.date.formatted(date: .complete, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.72))
                            }

                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(entry.moodKind.tint.opacity(0.28))
                                    .frame(width: 96, height: 96)
                                Circle()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    .frame(width: 96, height: 96)
                                Text(entry.moodKind.emoji)
                                    .font(.system(size: 44))
                            }
                        }

                        Text(moodDescriptor)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 12) {
                            snapshotTile(title: "Mood".localizedMoodText, value: entry.moodKind.title)
                            snapshotTile(title: "Time".localizedMoodText, value: entry.date.formatted(date: .omitted, time: .shortened))
                            snapshotTile(title: "Moment".localizedMoodText, value: dayPeriod)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        entry.moodKind.tint.opacity(0.48),
                                        Color.black.opacity(0.36)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                    if !entry.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What you felt".localizedMoodText)
                                .font(.headline)
                                .foregroundStyle(.white)

                            FlexibleTagLayout(spacing: 10, rowSpacing: 10) {
                                ForEach(entry.tags, id: \.self) { tag in
                                    Text(tag.localizedMoodText)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(entry.moodKind.tint.opacity(0.22))
                                        )
                                }
                            }
                        }
                        .padding(18)
                        .background(detailCardBackground)
                    }

                    detailCard(
                        title: "Reflection".localizedMoodText,
                        content: entry.localizedNoteText
                    )

                    if !AppReviewManager.shared.isDemoMode {
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                            dismiss()
                        } label: {
                            Label("Delete mood entry".localizedMoodText, systemImage: "trash")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(
                LinearGradient(
                    colors: [
                        entry.moodKind.tint.opacity(0.16),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Mood details".localizedMoodText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done".localizedMoodText) { dismiss() }
                }
            }
        }
    }

    private func detailCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(content)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
        }
        .padding(18)
        .background(detailCardBackground)
    }

    private func snapshotTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var detailCardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private var dayPeriod: String {
        let hour = Calendar.current.component(.hour, from: entry.date)
        switch hour {
        case 5..<12: return "Morning".localizedMoodText
        case 12..<17: return "Afternoon".localizedMoodText
        case 17..<22: return "Evening".localizedMoodText
        default: return "Night".localizedMoodText
        }
    }

    private var moodDescriptor: String {
        switch entry.moodKind.score {
        case 4.5...:
            return String(
                localized: "This was a high-energy, strongly positive check-in.",
                comment: "Mood detail description for the strongest positive mood state."
            )
        case 3.8..<4.5:
            return String(
                localized: "This check-in reflects a calm, positive emotional state.",
                comment: "Mood detail description for a calm and positive mood state."
            )
        case 3.0..<3.8:
            return String(
                localized: "This moment looks balanced and emotionally steady.",
                comment: "Mood detail description for a neutral and steady mood state."
            )
        case 2.0..<3.0:
            return String(
                localized: "This check-in suggests lower energy or some emotional weight.",
                comment: "Mood detail description for a lower-energy mood state."
            )
        default:
            return String(
                localized: "This was a difficult moment and may deserve extra context or care.",
                comment: "Mood detail description for the lowest mood state."
            )
        }
    }
}

private struct MoodCheckInSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (MoodEntry) -> Void

    @State private var selectedCheckInIndex = 4
    @State private var selectedTags: Set<String> = []
    @State private var noteText = ""
    @FocusState private var noteFieldFocused: Bool

    private let checkInLevels: [MoodCheckInLevel] = [
        MoodCheckInLevel(index: 0, title: "Very Unpleasant", subtitle: "heavy and strained", symbol: "cloud.rain.fill", colors: [.red, .orange], mood: .angry, suggestedTags: ["Drained", "Overwhelmed", "Irritated", "Anxious"]),
        MoodCheckInLevel(index: 1, title: "Unpleasant", subtitle: "running low", symbol: "cloud.fill", colors: [.orange, .pink], mood: .sad, suggestedTags: ["Sad", "Tired", "Unsettled", "Stressed"]),
        MoodCheckInLevel(index: 2, title: "Slightly Low", subtitle: "a bit off today", symbol: "cloud.sun.fill", colors: [.yellow, .orange], mood: .tired, suggestedTags: ["Distracted", "Flat", "Restless", "Quiet"]),
        MoodCheckInLevel(index: 3, title: "Neutral", subtitle: "steady and observant", symbol: "circle.hexagongrid.fill", colors: [.gray, .blue], mood: .neutral, suggestedTags: ["Neutral", "Thoughtful", "Focused", "Measured"]),
        MoodCheckInLevel(index: 4, title: "Pleasant", subtitle: "open and grounded", symbol: "sun.max.fill", colors: [.mint, .cyan], mood: .relaxed, suggestedTags: ["Calm", "Content", "Grateful", "Balanced"]),
        MoodCheckInLevel(index: 5, title: "Good", subtitle: "energized and warm", symbol: "sun.max.circle.fill", colors: [.green, .mint], mood: .happy, suggestedTags: ["Happy", "Motivated", "Connected", "Optimistic"]),
        MoodCheckInLevel(index: 6, title: "Very Pleasant", subtitle: "bright and uplifted", symbol: "sparkles", colors: [.yellow, .mint], mood: .joyful, suggestedTags: ["Joyful", "Excited", "Inspired", "Confident"])
    ]

    private var selectedLevel: MoodCheckInLevel {
        checkInLevels[selectedCheckInIndex]
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Log mood".localizedMoodText)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Choose the feeling that best matches this moment.".localizedMoodText)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    heroOrb
                    moodScale
                    selectedStateCard
                    tagsCard
                    notesCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(sheetBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localizedMoodText) { dismiss() }
                        .foregroundStyle(.white.opacity(0.8))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localizedMoodText) { saveEntry() }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var sheetBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.07, green: 0.10, blue: 0.16),
                Color(red: 0.03, green: 0.05, blue: 0.10),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroOrb: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Check-in".localizedMoodText)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(selectedCheckInIndex + 1) of \(checkInLevels.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.56))
            }

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    selectedLevel.colors.first?.opacity(0.98) ?? .mint,
                                    selectedLevel.colors.last?.opacity(0.74) ?? .cyan,
                                    Color.white.opacity(0.08)
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 120
                            )
                        )
                        .frame(width: 138, height: 138)

                    Circle()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        .frame(width: 138, height: 138)

                    Image(systemName: selectedLevel.symbol)
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 8) {
                    Text(selectedLevel.title.localizedMoodText)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(selectedLevel.subtitle.localizedMoodText.localizedCapitalized)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.76))

                    Text("Slide across the spectrum to fine tune this check-in.".localizedMoodText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.58))
                        .multilineTextAlignment(.center)
                }

                Text(selectedLevel.mood.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.66))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(22)
        .background(cardFill(colors: selectedLevel.colors))
        .overlay(cardStroke)
    }

    private var selectedStateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current check-in".localizedMoodText)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(selectedLevel.mood.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selectedLevel.mood.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }

            Text(selectionSummary)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.74))

            if !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedTags).sorted(), id: \.self) { tag in
                            Text(tag.localizedMoodText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.white.opacity(0.12)))
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(cardFill(colors: [selectedLevel.mood.tint.opacity(0.16), Color.white.opacity(0.03)]))
        .overlay(cardStroke)
    }

    private var moodScale: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Mood spectrum".localizedMoodText)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(selectedLevel.title.localizedMoodText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            GeometryReader { proxy in
                let width = proxy.size.width
                let count = CGFloat(max(checkInLevels.count - 1, 1))

                ZStack {
                    LinearGradient(
                        colors: [.red, .orange, .yellow, .mint, .green],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .clipShape(Capsule())
                    .padding(.horizontal, 18)

                    HStack(spacing: 0) {
                        ForEach(checkInLevels) { level in
                            VStack(spacing: 0) {
                                ZStack {
                                    Circle()
                                        .fill(level.index == selectedCheckInIndex ? Color.white : Color.white.opacity(0.16))
                                        .frame(
                                            width: level.index == selectedCheckInIndex ? 40 : 14,
                                            height: level.index == selectedCheckInIndex ? 40 : 14
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(level.index == selectedCheckInIndex ? 0.12 : 0.08), lineWidth: 1)
                                        )

                                    if level.index == selectedCheckInIndex {
                                        Image(systemName: level.symbol)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.black)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                updateSelectedLevel(level.index)
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let normalizedX = min(max(value.location.x - 18, 0), max(width - 36, 1))
                            let rawIndex = Int((normalizedX / max(width - 36, 1)) * count + 0.5)
                            let clampedIndex = min(max(rawIndex, 0), checkInLevels.count - 1)
                            if clampedIndex != selectedCheckInIndex {
                                updateSelectedLevel(clampedIndex)
                            }
                        }
                )
            }
            .frame(height: 56)

            VStack(alignment: .leading, spacing: 6) {
                Text(selectedLevel.title.localizedMoodText)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(selectedLevel.subtitle.localizedMoodText.localizedCapitalized)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
            }

            HStack {
                Text("Very unpleasant".localizedMoodText)
                Spacer()
                Text("Very pleasant".localizedMoodText)
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.62))
        }
        .padding(20)
        .background(cardFill(colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)]))
        .overlay(cardStroke)
    }

    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Describe it".localizedMoodText)
                .font(.headline)
                .foregroundStyle(.white)

            FlexibleTagLayout(spacing: 10, rowSpacing: 10) {
                ForEach(selectedLevel.suggestedTags, id: \.self) { tag in
                    let isSelected = selectedTags.contains(tag)
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.85)) {
                            if isSelected {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    } label: {
                        Text(tag.localizedMoodText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.82))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(isSelected ? 0.22 : 0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(cardFill(colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)]))
        .overlay(cardStroke)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Optional note".localizedMoodText)
                .font(.headline)
                .foregroundStyle(.white)

            TextField("What is influencing this feeling?".localizedMoodText, text: $noteText, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .focused($noteFieldFocused)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )

            HStack {
                Text("Optional context helps trends make more sense later.".localizedMoodText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.52))
                Spacer()
                Text("\(noteText.count)/140")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.52))
            }
        }
        .padding(18)
        .background(cardFill(colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)]))
        .overlay(cardStroke)
    }


    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
    }

    private func cardFill(colors: [Color]) -> some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var selectionSummary: String {
        if selectedTags.isEmpty {
            return localizedMoodFormat(
                "You’re checking in as %@. Add a few tags to make the trend history more meaningful.",
                selectedLevel.subtitle.localizedMoodText
            )
        }
        let localizedTags = selectedTags
            .sorted()
            .map { $0.localizedMoodText.localizedLowercase }
            .joined(separator: ", ")
        return localizedMoodFormat(
            "You’re feeling %@ with %@.",
            selectedLevel.subtitle.localizedMoodText,
            localizedTags
        )
    }

    private func saveEntry() {
        onSave(
            MoodEntry(
                date: Date(),
                moodKind: selectedLevel.mood,
                title: selectedLevel.title,
                tags: Array(selectedTags).sorted(),
                noteText: String(noteText.prefix(140))
            )
        )
        dismiss()
    }

    private func shortLabel(for level: MoodCheckInLevel) -> String {
        switch level.index {
        case 0: "Very low"
        case 1: "Low"
        case 2: "Off"
        case 3: "Neutral"
        case 4: "Good"
        case 5: "Great"
        default: "Bright"
        }
    }

    private func updateSelectedLevel(_ index: Int) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            selectedCheckInIndex = index
            selectedTags = []
        }
    }
}

private struct FlexibleTagLayout: Layout {
    let spacing: CGFloat
    let rowSpacing: CGFloat

    init(spacing: CGFloat = 8, rowSpacing: CGFloat = 8) {
        self.spacing = spacing
        self.rowSpacing = rowSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        guard maxWidth > 0 else {
            let totalHeight = subviews.reduce(CGFloat.zero) { $0 + $1.sizeThatFits(.unspecified).height + rowSpacing }
            let widest = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
            return CGSize(width: widest, height: max(totalHeight - rowSpacing, 0))
        }

        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextWidth = currentRowWidth == 0 ? size.width : currentRowWidth + spacing + size.width

            if nextWidth > maxWidth, currentRowWidth > 0 {
                totalHeight += currentRowHeight + rowSpacing
                currentRowWidth = size.width
                currentRowHeight = size.height
            } else {
                currentRowWidth = nextWidth
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }

        totalHeight += currentRowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = CGPoint(x: bounds.minX, y: bounds.minY)
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > bounds.maxX, origin.x > bounds.minX {
                origin.x = bounds.minX
                origin.y += rowHeight + rowSpacing
                rowHeight = 0
            }

            subview.place(at: origin, proposal: ProposedViewSize(width: size.width, height: size.height))
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

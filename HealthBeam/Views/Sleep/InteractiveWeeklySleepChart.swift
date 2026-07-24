import SwiftUI
import Charts
struct InteractiveWeeklySleepChart: View {
    let analyses: [DailySleepAnalysis]
    @Binding var selectedAnalysis: DailySleepAnalysis?
    @Namespace private var animation
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let baseDate = analyses.min(by: { $0.date < $1.date })?.date ?? Date()

        let weekday = calendar.component(.weekday, from: baseDate)
        let diff = (weekday + 5) % 7

        guard let startOfWeek = calendar.date(
            byAdding: .day,
            value: -diff,
            to: calendar.startOfDay(for: baseDate)
        ) else { return [] }

        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }

    private var weekDayKeys: [String] {
        weekDays.map { dayKey(for: $0) }
    }

    // MARK: - Uyku Periodları
    private var allPeriods: [SleepStagePeriod] {
        analyses.flatMap { $0.stagePeriods }
            .filter { $0.type != .inBed }
    }

    var body: some View {

        VStack(spacing: 24) {

            // MARK: - Chart
            Chart {

                ForEach(weekDays, id: \.self) { dayDate in

                    let key = dayKey(for: dayDate)

                    // Tap alanı
                    BarMark(
                        x: .value("Day", key),
                        y: .value("Empty", 86400)
                    )
                    .foregroundStyle(.clear)

                    // Sleep Blocks
                    ForEach(allPeriods) { period in
                        if let intersection = getIntersection(period: period, forColumnDate: dayDate) {

                            RectangleMark(
                                x: .value("Day", key),
                                yStart: .value("Start", intersection.yStart),
                                yEnd: .value("End", intersection.yEnd)
                            )
                            .foregroundStyle(period.type.color.gradient)
                            .cornerRadius(2)
                        }
                    }
                }
            }

            // MARK: - X Scale categorical (HİZALAMA FIX)
            .chartXScale(domain: weekDayKeys)

            // MARK: - Y Scale
            .chartYScale(domain: 0...86400)

            // MARK: - Y Axis
            .chartYAxis {
                AxisMarks(position: .leading,
                          values: [0, 21600, 43200, 64800, 86400]) { value in

                    AxisGridLine(
                        stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                    )
                    .foregroundStyle(.gray.opacity(0.25))

                    if let seconds = value.as(Double.self) {
                        AxisValueLabel {
                            Text(formatChartTime(86400 - seconds))
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // MARK: - ✅ X Axis artık tam oturur
            .chartXAxis {
                AxisMarks(values: weekDayKeys) { value in

                    AxisTick()
                    AxisGridLine()

                    AxisValueLabel {
                        if let key = value.as(String.self),
                           let date = dateFromKey(key) {

                            VStack(spacing: 4) {

                                Text(weekdayAbbrev(for: date))
                                    .font(.caption2.bold())
                                    .foregroundStyle(
                                        isDateSelected(date)
                                        ? .white
                                        : .secondary
                                    )

                                if isDateSelected(date) {
                                    Circle()
                                        .fill(.indigo)
                                        .frame(width: 4, height: 4)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Circle()
                                        .fill(.clear)
                                        .frame(width: 4, height: 4)
                                }
                            }
                        }
                    }
                }
            }

            // MARK: - Tap Gesture Fix
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in

                            let xPos = location.x - geo[proxy.plotFrame!].origin.x

                            guard let key: String = proxy.value(atX: xPos) else { return }

                            guard let tappedDate = dateFromKey(key) else { return }

                            let calendar = Calendar.current

                            if let match = analyses.first(where: {
                                calendar.isDate($0.date, inSameDayAs: tappedDate)
                            }) {

                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    if selectedAnalysis?.id == match.id {
                                        selectedAnalysis = nil
                                    } else {
                                        selectedAnalysis = match
                                    }
                                }
                            }
                        }
                }
            }

            .frame(height: 240)
            .padding(.horizontal, 20)

            // MARK: - Alt Panel
            if let selected = selectedAnalysis {
                SleepDayDetailView(analysis: selected)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                SleepLegendView()
                    .padding(.top, 8)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Key Helpers

    private func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func dateFromKey(_ key: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: key)
    }

    // MARK: - Intersection

    private func getIntersection(period: SleepStagePeriod, forColumnDate date: Date)
    -> (yStart: Double, yEnd: Double)? {

        let calendar = Calendar.current

        guard let columnStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date),
              let columnEnd = calendar.date(byAdding: .day, value: 1, to: columnStart)
        else { return nil }

        if period.startDate >= columnEnd || period.endDate <= columnStart {
            return nil
        }

        let intersectStart = max(period.startDate, columnStart)
        let intersectEnd = min(period.endDate, columnEnd)

        let startSeconds = intersectStart.timeIntervalSince(columnStart)
        let endSeconds = intersectEnd.timeIntervalSince(columnStart)

        return (86400 - startSeconds, 86400 - endSeconds)
    }

    // MARK: - Time Format

    private func formatChartTime(_ seconds: Double) -> String {

        let total = Int(seconds)
        let normalized = total >= 86400 ? total - 86400 : total

        switch normalized {
        case 0, 86400: return "12:00"
        case 43200: return "00:00"
        case 21600: return "18:00"
        case 64800: return "06:00"
        default:
            let h = normalized / 3600
            let m = (normalized % 3600) / 60

            var hour = h + 12
            if hour >= 24 { hour -= 24 }

            return String(format: "%02d:%02d", hour, m)
        }
    }

    private func isDateSelected(_ date: Date) -> Bool {
        guard let selected = selectedAnalysis else { return false }
        return Calendar.current.isDate(selected.date, inSameDayAs: date)
    }

    private func weekdayAbbrev(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
}
struct SleepDayDetailView: View {
    let analysis: DailySleepAnalysis
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .lastTextBaseline) {
                Text(analysis.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "bed.double.fill")
                    Text(formatDuration(analysis.totalAsleepTime))
                }
                .font(.subheadline.bold())
                .foregroundStyle(.indigo.gradient)
            }
            Divider().overlay(.white.opacity(0.1))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SleepStatCard(title: String(localized: "Deep Sleep"), value: analysis.duration(of: .deep), color: .indigo, icon: "zzz")
                SleepStatCard(title: String(localized: "REM Sleep"), value: analysis.duration(of: .rem), color: .purple, icon: "sparkles")
                SleepStatCard(title: String(localized: "Core / Light"), value: analysis.duration(of: .light), color: .cyan, icon: "moon.fill")
                SleepStatCard(title: String(localized: "Awake"), value: analysis.duration(of: .awake), color: .orange, icon: "eye.fill")
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
struct SleepStatCard: View {
    let title: String
    let value: TimeInterval
    let color: Color
    let icon: String
    var body: some View {
        HStack {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.caption.bold()).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption2).foregroundStyle(.secondary)
                Text(formatDuration(value))
                    .font(.system(.callout, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
struct SleepLegendView: View {
    var body: some View {
        HStack(spacing: 16) {
            legendItem(color: .indigo, text: String(localized: "Deep"))
            legendItem(color: .purple, text: String(localized: "REM"))
            legendItem(color: .cyan, text: String(localized: "Light"))
            legendItem(color: .orange, text: String(localized: "Awake"))
        }
        .padding(.top, 8)
    }
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.caption.bold()).foregroundStyle(.secondary)
        }
    }
}

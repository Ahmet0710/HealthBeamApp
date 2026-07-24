import SwiftUI
import Charts
import HealthKit

enum HeartDetailTimeRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    var id: String { rawValue }

    var localizedTitle: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

struct HeartDetailView: View {
    let metric: HeartMetric
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    @State private var fetchedEntries: [HeartEntry] = []
    @State private var isLoading = false
    @State private var selectedTimeRange: HeartDetailTimeRange = .month
    @State private var displayDate = Date()
    @State private var selectedDate: Date?
    @State private var selectedValue: Double?

    private var color: Color {
        switch metric {
        case .heartRate: return .red
        case .restingHeartRate: return .orange
        case .heartRateVariability: return .purple
        case .walkingHeartRate: return .blue
        case .cardioFitness: return .green
        case .cardioRecovery: return .pink
        }
    }

    private var gradient: LinearGradient {
        LinearGradient(colors: [color, color.opacity(0.3)], startPoint: .top, endPoint: .bottom)
    }

    private var valueGradient: LinearGradient {
        LinearGradient(colors: [.white, color], startPoint: .top, endPoint: .bottom)
    }

    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let grouped: [Date: [HeartEntry]] = Dictionary(grouping: fetchedEntries) { entry in
            switch selectedTimeRange {
            case .day: return calendar.dateInterval(of: .hour, for: entry.date)?.start ?? entry.date
            case .week, .month: return calendar.startOfDay(for: entry.date)
            case .year: return calendar.dateInterval(of: .month, for: entry.date)?.start ?? entry.date
            }
        }
        return grouped.map { date, values in
            let avg = values.reduce(0) { $0 + $1.value } / Double(values.count)
            return ChartDataPoint(date: date, value: avg, totalSleepDurationMinutes: 0, timeInBedMinutes: 0, lightSleepDurationMinutes: 0)
        }
        .sorted { $0.date < $1.date }
    }

    private var averageValue: Double? {
        guard !fetchedEntries.isEmpty else { return nil }
        return fetchedEntries.reduce(0) { $0 + $1.value } / Double(fetchedEntries.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                if isLoading {
                    ProgressView().frame(height: 220).tint(.white)
                } else {
                    chartView.frame(height: 220)
                }
                timeRangePicker
                dateNavigatorView
                statsView
                historyView
            }
            .padding()
        }
        .background(gradient.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    ZStack {
                        Circle().fill(.white.opacity(0.9)).frame(width: 32, height: 32)
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold)).foregroundStyle(color)
                    }
                }
            }
        }
        .onAppear { Task { await loadData() } }
        .onChange(of: selectedTimeRange) { Task { await loadData() } }
        .onChange(of: displayDate) { Task { await loadData() } }
    }

    private func loadData() async {
        isLoading = true
        var newEntries: [HeartEntry] = []
        let managerRange: HeartTimeRange = {
            switch selectedTimeRange {
            case .day: return .day
            case .week: return .week
            case .month: return .month
            case .year: return .year
            }
        }()
        newEntries = await healthKitManager.fetchHeartEntries(metric: metric, range: managerRange, referenceDate: displayDate)
        await MainActor.run {
            self.fetchedEntries = newEntries.sorted { $0.date > $1.date }
            self.isLoading = false
        }
    }

    private var headerView: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.localizedTitle).font(.title3.bold()).foregroundStyle(.white)
                Text(dateFormatted(selectedDate ?? displayDate)).font(.caption).foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            if let val = selectedValue ?? chartData.last?.value {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(val))")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(valueGradient)
                    Text(metric.unit).font(.callout.bold()).foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }

    private func dateFormatted(_ date: Date) -> String {
        switch selectedTimeRange {
        case .day: return date.formatted(date: .omitted, time: .shortened)
        case .year: return date.formatted(.dateTime.month(.wide).year())
        default: return date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    private var timeRangePicker: some View {
        Picker("Range", selection: $selectedTimeRange) {
            ForEach(HeartDetailTimeRange.allCases) { range in Text(range.localizedTitle).tag(range) }
        }
        .pickerStyle(.segmented).colorScheme(.dark)
    }

    @ViewBuilder
    private var chartView: some View {
        if chartData.isEmpty {
            ContentUnavailableView { Label("No Data", systemImage: "chart.bar.xaxis").foregroundStyle(.white) }
        } else {
            Chart(chartData) { point in
                AreaMark(x: .value("Date", point.date), y: .value("Value", point.value))
                    .foregroundStyle(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                    .foregroundStyle(.white).lineStyle(.init(lineWidth: 3)).interpolationMethod(.catmullRom)
                
                if let selectedDate, Calendar.current.isDate(selectedDate, inSameDayAs: point.date) {
                    RuleMark(x: .value("Selected", selectedDate))
                        .foregroundStyle(.white.opacity(0.3)).lineStyle(.init(lineWidth: 2, dash: [5, 5]))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(DragGesture().onChanged { value in
                            if let plotFrame = proxy.plotFrame {
                                let x = value.location.x - geo[plotFrame].origin.x
                                if let date: Date = proxy.value(atX: x),
                                   let point = chartData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                    self.selectedDate = point.date
                                    self.selectedValue = point.value
                                }
                            }
                        }.onEnded { _ in self.selectedDate = nil; self.selectedValue = nil })
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.2))
                    if let date = value.as(Date.self) { AxisValueLabel { Text(xAxisLabel(for: date)).foregroundStyle(.white.opacity(0.7)) } }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(.white.opacity(0.2))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }

    private func xAxisLabel(for date: Date) -> String {
        switch selectedTimeRange {
        case .day: return date.formatted(date: .omitted, time: .shortened)
        case .week: return date.formatted(.dateTime.weekday(.abbreviated))
        case .month: return date.formatted(.dateTime.day())
        case .year: return date.formatted(.dateTime.month(.narrow))
        }
    }

    private var statsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics").font(.title2.bold()).foregroundStyle(.white)
            if let avg = averageValue {
                HeartStatCard(title: "Average", value: avg, unit: metric.unit, color: color)
            }
        }
    }

    private var historyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History").font(.title2.bold()).foregroundStyle(.white)
            let sorted = fetchedEntries.sorted { $0.date > $1.date }
            ForEach(sorted.prefix(50)) { entry in
                HStack {
                    Text("\(Int(entry.value)) \(metric.unit)").font(.headline)
                    Spacer()
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                }
                .padding().background(.ultraThinMaterial).cornerRadius(10)
            }
        }
    }

    private var dateNavigatorView: some View {
        HStack {
            Button { moveDate(by: -1) } label: { Image(systemName: "chevron.left").foregroundStyle(.white) }
            Spacer(); Text(dateNavigatorTitle).font(.headline).foregroundStyle(.white); Spacer()
            Button { moveDate(by: 1) } label: { Image(systemName: "chevron.right").foregroundStyle(.white) }
        }
    }

    private var dateNavigatorTitle: String {
        switch selectedTimeRange {
        case .day: return displayDate.formatted(date: .abbreviated, time: .omitted)
        case .month: return displayDate.formatted(.dateTime.month(.wide).year())
        case .year: return displayDate.formatted(.dateTime.year())
        default: return ""
        }
    }

    private func moveDate(by value: Int) {
        let component: Calendar.Component = {
            switch selectedTimeRange {
            case .day: return .day
            case .week: return .weekOfYear
            case .month: return .month
            case .year: return .year
            }
        }()
        if let newDate = Calendar.current.date(byAdding: component, value: value, to: displayDate) { displayDate = newDate }
    }
}

private struct HeartStatCard: View {
    let title: String; let value: Double?; let unit: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline).foregroundStyle(.secondary)
            if let value {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(value))").font(.title3.bold()).foregroundStyle(color)
                    Text(unit).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading).background(.ultraThinMaterial).cornerRadius(12)
    }
}

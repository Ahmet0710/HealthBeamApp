import SwiftUI
import Charts

enum DetailTimeRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    var id: String { rawValue }

    var localizedTitle: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

struct MeasurementDetailView: View {
    let type: MeasurementType
    @Binding var allEntries: [MeasurementEntry]
    let onDelete: (Set<UUID>) -> Void

    @EnvironmentObject private var measurementSystemManager: MeasurementSystemManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTimeRange: DetailTimeRange = .month
    @State private var displayDate = Date()
    @State private var selectedDate: Date?
    @State private var selectedValue: Double?

    private var color: Color { MeasurementRowView.color(for: type) }
    private var gradient: LinearGradient {
        LinearGradient(colors: [color, color.opacity(0.3)], startPoint: .top, endPoint: .bottom)
    }
    private var valueGradient: LinearGradient {
        LinearGradient(colors: [.white, color], startPoint: .top, endPoint: .bottom)
    }

    private func convertedValue(_ value: Double) -> Double {
        switch type {
        case .weight, .leanBodyMass:
            return measurementSystemManager.measurementSystem == .Metric ? value : value * 2.20462
        case .height, .waistCircumference:
            return measurementSystemManager.measurementSystem == .Metric ? value : value * 0.3937007874
        default: return value
        }
    }

    private var currentUnit: String {
        switch type {
        case .weight, .leanBodyMass: return measurementSystemManager.measurementSystem == .Metric ? "kg" : "lb"
        case .height, .waistCircumference: return measurementSystemManager.measurementSystem == .Metric ? "cm" : "in"
        default: return type.unit
        }
    }

    private var entriesInCurrentInterval: [MeasurementEntry] {
        let calendar = Calendar.current
        let component: Calendar.Component = {
            switch selectedTimeRange {
            case .day: return .day
            case .week: return .weekOfYear
            case .month: return .month
            case .year: return .year
            }
        }()
        guard let interval = calendar.dateInterval(of: component, for: displayDate) else { return [] }
        return allEntries.filter { $0.type == type && interval.contains($0.date) }
    }

    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let grouped: [Date: [MeasurementEntry]] = Dictionary(grouping: entriesInCurrentInterval) { entry in
            switch selectedTimeRange {
            case .day: return calendar.dateInterval(of: .hour, for: entry.date)?.start ?? entry.date
            case .week, .month: return calendar.startOfDay(for: entry.date)
            case .year: return calendar.dateInterval(of: .month, for: entry.date)?.start ?? entry.date
            }
        }
        return grouped.map { date, values in
            let avg = values.reduce(0) { $0 + $1.value } / Double(values.count)
            return ChartDataPoint(date: date, value: convertedValue(avg), totalSleepDurationMinutes: 0, timeInBedMinutes: 0, lightSleepDurationMinutes: 0)
        }
        .sorted { $0.date < $1.date }
    }

    private var averageValue: Double? {
        guard !entriesInCurrentInterval.isEmpty else { return nil }
        let avg = entriesInCurrentInterval.reduce(0) { $0 + $1.value } / Double(entriesInCurrentInterval.count)
        return convertedValue(avg)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                chartView.frame(height: 220)
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
    }

    private var headerView: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(type.localizedTitle).font(.title3.bold()).foregroundStyle(.white)
                Text(dateFormatted(selectedDate ?? displayDate)).font(.caption).foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            if let val = selectedValue ?? chartData.last?.value {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", val))
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(valueGradient)
                    Text(currentUnit).font(.callout.bold()).foregroundStyle(.white.opacity(0.7))
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
            ForEach(DetailTimeRange.allCases) { range in Text(range.localizedTitle).tag(range) }
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
            if let avg = averageValue { StatCards(title: "Average", value: avg, unit: currentUnit, color: color) }
        }
    }

    private var historyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History").font(.title2.bold()).foregroundStyle(.white)
            let sorted = entriesInCurrentInterval.sorted { $0.date > $1.date }
            ForEach(sorted.prefix(50)) { entry in
                HStack {
                    Text("\(convertedValue(entry.value), specifier: "%.1f") \(currentUnit)").font(.headline)
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

private struct StatCards: View {
    let title: String; let value: Double?; let unit: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline).foregroundStyle(.secondary)
            if let value {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", value)).font(.title3.bold()).foregroundStyle(color)
                    Text(unit).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading).background(.ultraThinMaterial).cornerRadius(12)
    }
}

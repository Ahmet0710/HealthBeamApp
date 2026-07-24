import SwiftUI
import Charts
struct MeasurementRowView: View {
    let type: MeasurementType
    let entries: [MeasurementEntry]

    @EnvironmentObject private var measurementSystemManager: MeasurementSystemManager

    @State private var selectedDate: Date?
    @State private var selectedValue: Double?

    private var accentColor: Color { Self.color(for: type) }
    private var accentGradient: LinearGradient { LinearGradient(colors: [accentColor, accentColor.opacity(0.3)], startPoint: .top, endPoint: .bottom) }
    private var lastEntry: MeasurementEntry? { entries.sorted { $0.date > $1.date }.first }
    private var valueChange: Double? {
        let sorted = entries.sorted { $0.date > $1.date }
        guard sorted.count > 1 else { return nil }
        return sorted[0].value - sorted[1].value
    }

    private var chartData: [ChartDataPoint] {
        let dailyGrouped = Dictionary(grouping: entries) { Calendar.current.startOfDay(for: $0.date) }
        return dailyGrouped.map { date, entriesInDay in
            let avgValue = entriesInDay.reduce(0) { $0 + $1.value } / Double(entriesInDay.count)
            return ChartDataPoint(date: date, value: avgValue, totalSleepDurationMinutes: 0, timeInBedMinutes: 0, lightSleepDurationMinutes: 0)
        }.sorted { $0.date < $1.date }
    }

    private var yAxisDomain: ClosedRange<Double>? {
        guard !chartData.isEmpty else { return nil }
        let values = chartData.map { $0.value }
        guard let minValue = values.min(), let maxValue = values.max() else { return nil }
        if minValue == maxValue {
            let padding = abs(minValue) > 0 ? abs(minValue) * 0.1 : 1
            return (minValue - padding)...(maxValue + padding)
        }
        let padding = (maxValue - minValue) * 0.1
        return max(0, minValue - padding)...(maxValue + padding)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            chartView.frame(height: 150)
        }
        .padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom)))
    }

    private var headerView: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
                Text(type.localizedTitle).font(.title2).fontWeight(.bold)
                if let date = selectedDate ?? lastEntry?.date {
                    Text(date, style: .date).font(.subheadline).foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                if let entry = lastEntry {
                    if type.rawValue == "Time In Bed" {
                        let value = selectedValue ?? entry.value
                        let hours = Int(value) / 3600
                        let minutes = (Int(value) % 3600) / 60
                        Text("\(hours) hours \(minutes) mins")
                            .font(.title).fontWeight(.bold).foregroundStyle(accentGradient)
                            .animation(.easeInOut, value: selectedValue)
                    } else {
                        let value = selectedValue ?? entry.value
                        Text(formattedValue(for: type, value: value))
                            .font(.title).fontWeight(.bold).foregroundStyle(accentGradient)
                            .animation(.easeInOut, value: selectedValue)
                    }
                    if let change = valueChange, selectedValue == nil {
                        Text(String(format: "%+.1f", change)).font(.subheadline).foregroundColor(change >= 0 ? .green : .red)
                    }
                } else { Text("No Data").font(.title3).foregroundColor(.secondary) }
            }
        }
    }

    @ViewBuilder private var chartView: some View {
        if chartData.isEmpty {
            VStack {
                Spacer()
                Text("No Avaliable data Between Selected Dates")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(height: 150)
            .background(Color.clear)
        } else {
            Chart(chartData) { point in
                AreaMark(x: .value("Date", point.date), y: .value("Value", point.value))
                    .foregroundStyle(accentGradient.opacity(0.4)).interpolationMethod(.catmullRom)
                LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                    .foregroundStyle(accentGradient).interpolationMethod(.catmullRom).lineStyle(StrokeStyle(lineWidth: 3))
            }
            .chartYScale(domain: yAxisDomain ?? 0...100)
            .chartYAxis {
                if type.rawValue == "Time In Bed" {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        if let seconds = value.as(Double.self) {
                            let totalMinutes = Int(seconds / 60)
                            let hours = totalMinutes / 60
                            let minutes = totalMinutes % 60
                            AxisValueLabel("\(hours)s \(minutes)d")
                        }
                    }
                } else if type == .weight || type == .height || type == .waistCircumference || type == .leanBodyMass {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        if let val = value.as(Double.self) {
                            AxisValueLabel(formattedYAxisValue(for: type, value: val))
                        }
                    }
                } else if type == .bodyFatPercentage || type == .bodyMassIndex || type == .bodyTemperature || type == .basalBodyTemperature || type == .wristTemperature {
                    AxisMarks()
                } else {
                    AxisMarks()
                }
            }
            .chartPlotStyle { $0.clipped() }
            .chartOverlay { proxy in
                ChartInteractionOverlay(proxy: proxy, data: chartData, selectedValue: $selectedValue, selectedDate: $selectedDate, type: type, measurementSystemManager: measurementSystemManager)
            }
            .chartBackground { proxy in
                ChartInteractionBackground(proxy: proxy, color: accentColor, selectedValue: selectedValue, selectedDate: selectedDate)
            }
        }
    }

    private func formattedValue(for type: MeasurementType, value: Double) -> String {
        switch type {
        case .weight:
            return measurementSystemManager.measurementSystem.formatWeight(value)
        case .height, .waistCircumference:
            return measurementSystemManager.measurementSystem.formatHeight(value)
        case .bodyFatPercentage:
            return String(format: "%.1f%%", value)
        case .bodyTemperature, .basalBodyTemperature, .wristTemperature:
            return String(format: "%.1f °C", value)
        case .leanBodyMass:
            return measurementSystemManager.measurementSystem.formatWeight(value)
        case .bodyMassIndex:
            return String(format: "%.1f", value)
        }
    }

    private func formattedYAxisValue(for type: MeasurementType, value: Double) -> String {
        switch type {
        case .weight:
            return measurementSystemManager.measurementSystem.formatWeight(value)
        case .height, .waistCircumference:
            return measurementSystemManager.measurementSystem.formatHeight(value)
        case .leanBodyMass:
            return measurementSystemManager.measurementSystem.formatWeight(value)
        default:
            return String(format: "%.1f", value)
        }
    }
}
extension MeasurementRowView {
    static func color(for type: MeasurementType) -> Color {
        switch type {
        case .weight: return Color(red: 0.1, green: 0.6, blue: 0.2)
        case .height: return Color(red: 0.3, green: 0.7, blue: 1.0)
        case .bodyFatPercentage: return .orange
        case .leanBodyMass: return Color(red: 0.1, green: 0.5, blue: 0.5)
        case .bodyTemperature: return Color(red: 1.0, green: 0.0, blue: 1.0)
        case .waistCircumference: return .yellow
        case .basalBodyTemperature: return Color(red: 1.0, green: 0.4, blue: 0.4)
        case .wristTemperature: return Color(red: 0.6, green: 0.5, blue: 0.9)
        case .bodyMassIndex: return .green
        }
    }
}
private struct ChartInteractionOverlay: View {
    let proxy: ChartProxy
    let data: [ChartDataPoint]
    @Binding var selectedValue: Double?
    @Binding var selectedDate: Date?
    let type: MeasurementType
    let measurementSystemManager: MeasurementSystemManager

    var body: some View {
        GeometryReader { geo in
            Rectangle().fill(.clear).contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if let date: Date = proxy.value(atX: value.location.x),
                           let point = data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                            self.selectedDate = point.date
                            self.selectedValue = point.value
                        }
                    }.onEnded { _ in
                        self.selectedDate = nil
                        self.selectedValue = nil
                    }
                )
        }
    }
}
private struct ChartInteractionBackground: View {
    let proxy: ChartProxy
    let color: Color
    let selectedValue: Double?
    let selectedDate: Date?

    var body: some View {
        if let date = selectedDate, let value = selectedValue,
           let xPos = proxy.position(forX: date), let yPos = proxy.position(forY: value) {
            Rectangle().fill(.secondary).frame(width: 1, height: proxy.plotSize.height).position(x: xPos, y: proxy.plotSize.height / 2)
            Circle().strokeBorder(.primary, lineWidth: 2).background(Circle().fill(color)).frame(width: 12, height: 12).position(x: xPos, y: yPos)
        }
    }
}

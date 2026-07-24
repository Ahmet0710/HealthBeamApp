import SwiftUI
import Charts

struct ECGChartView: View {
    var signals: [ECGPoint]

    var body: some View {
        VStack(spacing: 15) {
            chartRow(data: signals, range: 0...10, showXAxis: false)
            chartRow(data: signals, range: 10...20, showXAxis: false)
            chartRow(data: signals, range: 20...30, showXAxis: true)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    @ViewBuilder
    private func chartRow(data: [ECGPoint], range: ClosedRange<Double>, showXAxis: Bool) -> some View {
        let filteredData = data.filter { $0.time >= range.lowerBound && $0.time < range.upperBound }
        VStack(alignment: .leading, spacing: 0) {
            Chart(filteredData) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value("Voltage", point.voltage)
                )
                .foregroundStyle(.red)
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
            .chartYScale(domain: -1.0...1.5)
            .chartXScale(domain: range)
            .chartYAxis(.hidden)
            .chartXAxis {
                if showXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                } else {
                    AxisMarks { _ in
                        AxisGridLine()
                    }
                }
            }
            .frame(height: 80)
        }
    }
}

import SwiftUI
import Charts

struct ECGStripRow: View {
    let data: [ECGPoint]
    let timeRange: ClosedRange<Double>

    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.time),
                y: .value("Voltage", point.voltage)
            )
            .foregroundStyle(.black)
            .lineStyle(StrokeStyle(lineWidth: 1.2, lineJoin: .round))
            .interpolationMethod(.linear)
        }
        .chartYScale(domain: -1.0...1.5)
        .chartXScale(domain: timeRange)
        .chartXAxis {
            AxisMarks(values: .stride(by: 1.0)) { value in
                if let t = value.as(Double.self) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.clear)
                    AxisValueLabel {
                        Text("\(Int(t) % 10)s")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 120)
        .clipped()
    }
}

import SwiftUI
import Charts

struct ECGStripView: View {
    let data: [ECGPoint]
    let range: ClosedRange<Double>

    var body: some View {
        let filteredData = data.filter { $0.time >= range.lowerBound && $0.time < range.upperBound }
        ZStack {
            ECGGrid()
            Chart(filteredData) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value("Voltage", point.voltage)
                )
                .foregroundStyle(Color(red: 0.8, green: 0.0, blue: 0.0))
                .lineStyle(StrokeStyle(lineWidth: 1.5, lineJoin: .round))
            }
            .chartYScale(domain: -1.0...1.5)
            .chartXScale(domain: range)
            .chartXAxis {
                AxisMarks(values: .stride(by: 1.0)) { value in
                    if let t = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(Int(t))s")
                                .font(.system(size: 8, weight: .regular))
                                .foregroundStyle(.gray)
                                .offset(y: 5)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .padding(.bottom, 20)
            .padding(.top, 10)
        }
        .frame(maxHeight: .infinity)
        .clipShape(Rectangle())
    }
}

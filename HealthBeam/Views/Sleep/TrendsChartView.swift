import SwiftUI
import Charts
struct TrendsChartViews: View {
    let data: [ChartDataPoint]
    let metric: HealthMetric
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Week", point.date, unit: .weekOfYear),
                y: .value(metric.rawValue, point.value)
            )
            .foregroundStyle(metric.color)
            .interpolationMethod(.catmullRom)
            AreaMark(
                x: .value("Week", point.date, unit: .weekOfYear),
                y: .value(metric.rawValue, point.value)
            )
            .foregroundStyle(LinearGradient(
                gradient: Gradient(colors: [metric.color.opacity(0.4), .clear]),
                startPoint: .top,
                endPoint: .bottom
            ))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { value in
                AxisGridLine()
                AxisTick()
                if let date = value.as(Date.self) {
                    AxisValueLabel(date.formatted(.dateTime.month(.abbreviated)), centered: false)
                }
            }
        }
        .frame(height: 200)
    }
}

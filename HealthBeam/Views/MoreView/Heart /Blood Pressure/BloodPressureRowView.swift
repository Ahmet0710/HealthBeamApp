import SwiftUI
import Charts

struct BloodPressureRowView: View {

    let entries: [BloodPressureEntry]
    let range: HeartTimeRange
    let referenceDate: Date

    private var points: [BloodPressurePoint] {
        switch range {
        case .day:
            return entries.forDay(referenceDate)
        case .week:
            return entries.forWeek(referenceDate)
        case .month:
            return entries.forMonth(referenceDate)
        case .year:
            return entries.forYear(referenceDate)
        }
    }

    private var latestPoint: BloodPressurePoint? {
        points.sorted { $0.date > $1.date }.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Blood Pressure")
                    .font(.title3.bold())

                Spacer()

                if let point = latestPoint {
                    BloodPressureValueText(
                        systolic: point.systolic,
                        diastolic: point.diastolic
                    )
                }
            }

            if points.isEmpty {
                Text("No data")
                    .foregroundStyle(.secondary)
                    .frame(height: 120)
            } else {
                Chart(points) { point in

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Systolic", point.systolic)
                    )
                    .foregroundStyle(.red)
                    .symbolSize(40)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Diastolic", point.diastolic)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(40)
                }
                .frame(height: 120)
                .chartYScale(domain: 40...200)
                .chartPlotStyle { $0.clipped() }
            }
        }
        .padding()
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

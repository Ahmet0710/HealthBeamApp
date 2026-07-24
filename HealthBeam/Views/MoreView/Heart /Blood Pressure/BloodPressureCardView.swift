import SwiftUI
import Charts

struct BloodPressureCardView: View {

    let entries: [BloodPressureEntry]
    let range: HeartTimeRange
    let referenceDate: Date

    // MARK: - Processed Points
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

            // HEADER ALANI
            HStack(alignment: .top) { // Üstten hizalayarak başlık ile değeri denkleştiriyoruz
                VStack(alignment: .leading, spacing: 4) {
                    Text("Blood Pressure")
                        .font(.title3.bold())

                    if let last = latestPoint {
                        Text(last.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer() // Bu artık düzgün çalışacak çünkü ValueText sıkıştırıldı

                if let last = latestPoint {
                    BloodPressureValueText(
                        systolic: last.systolic,
                        diastolic: last.diastolic
                    )
                    // İsterseniz hizayı "Cardio" kartındaki "30 bpm" ile birebir tutmak için
                    // hafif bir yukarı öteleme (offset) verebilirsiniz:
                    // .offset(y: 2)
                }
            }

            // CHART ALANI
            if points.isEmpty {
                Text("No data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity) // Ortalamak için
            } else {
                Chart {
                    ForEach(points) { point in
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Systolic", point.systolic)
                        )
                        .foregroundStyle(.red)
                        .symbolSize(45)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Diastolic", point.diastolic)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(45)
                    }
                }
                .frame(height: 120)
                .chartPlotStyle { $0.clipped() }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

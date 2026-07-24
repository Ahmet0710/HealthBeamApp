import SwiftUI
import Charts

struct AFibHistoryCardView: View {

    let entries: [AFibWeeklyEntry]
    let range: HeartTimeRange

    @State private var selectedEntry: AFibWeeklyEntry?

    private var visibleEntries: [AFibWeeklyEntry] {
        switch range {
        case .week:
            return entries.suffix(1)
        case .month:
            return entries
        default:
            return []
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // HEADER
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AFib History")
                        .font(.title3.bold())

                    // 👇 SADECE DOKUNULUNCA TARİH
                    if let entry = selectedEntry {
                        Text(entry.weekRangeText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // 👇 SADECE DOKUNULUNCA % DEĞER
                if let entry = selectedEntry {
                    Text(entry.displayPercentageText)
                        .font(.headline.bold())
                        .foregroundStyle(.orange)
                }
            }

            // CHART
            Chart {
                ForEach(visibleEntries) { entry in
                    PointMark(
                        x: .value("Week", entry.weekStart),
                        y: .value("AFib %", entry.displayPercentage)
                    )
                    .symbolSize(80)
                    .foregroundStyle(.orange)
                }
            }
            .frame(height: 120)
            .chartYScale(domain: 0...100)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x - geo[proxy.plotFrame!].origin.x
                                    if let date: Date = proxy.value(atX: x) {
                                        selectedEntry = visibleEntries.min {
                                            abs($0.weekStart.timeIntervalSince(date)) <
                                            abs($1.weekStart.timeIntervalSince(date))
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    // 👈 parmak kalkınca her şey gizlensin
                                    selectedEntry = nil
                                }
                        )
                }
            }
        }
        .padding()
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

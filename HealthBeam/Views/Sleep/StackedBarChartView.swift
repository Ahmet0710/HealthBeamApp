import SwiftUI
struct StackedBarChartView: View {
	let analyses: [DailySleepAnalysis]
	@Binding var selectedAnalysis: DailySleepAnalysis?

	private var dateFormatter: DateFormatter {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US")
		formatter.dateFormat = "EEE"
		return formatter
	}
	private let barMaxHeight: CGFloat = 120
	private let dayLabelHeight: CGFloat = 20
	var body: some View {
		HStack(alignment: .bottom, spacing: 6) {
			ForEach(analyses) { analysis in
				VStack(spacing: 4) {
					GeometryReader { geo in
						VStack(spacing: 0) {
							Spacer(minLength: 0)
							if analysis.totalInBedTime > 0 {
								ForEach(analysis.stagePeriods.sorted { $0.startDate < $1.startDate }) { period in
									Rectangle()
										.fill(period.type.color)
										.frame(height: barHeight(for: period.duration, in: geo.size.height))
								}
							} else {
								Color.clear
									.frame(height: 1)
							}
						}
						.frame(height: barMaxHeight)
						.clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
						.opacity(selectedAnalysis?.id == analysis.id ? 1.0 : 0.7)
						.scaleEffect(selectedAnalysis?.id == analysis.id ? 1.05 : 1.0)
						.animation(.easeInOut, value: selectedAnalysis)
					}
					.frame(height: barMaxHeight)
					Text(dateFormatter.string(from: analysis.date))
						.font(.caption2)
						.foregroundColor(.secondary)
						.frame(height: dayLabelHeight)
						.frame(maxWidth: .infinity)
						.fixedSize(horizontal: false, vertical: true)
				}
				.frame(maxWidth: .infinity)
				.contentShape(Rectangle())
				.onTapGesture {
					if selectedAnalysis?.id == analysis.id {
						selectedAnalysis = nil
					} else {
						selectedAnalysis = analysis
					}
				}
			}
		}
		.padding(.horizontal, 8)
		.padding(.bottom, 8)
	}
	private func barHeight(for duration: TimeInterval, in totalHeight: CGFloat) -> CGFloat {
		let maxTimeInBed = analyses.map { $0.totalInBedTime }.max() ?? 1
		guard maxTimeInBed > 0, duration > 0 else { return 0 }
		let height = max(1, barMaxHeight * (duration / maxTimeInBed))
		return min(height, barMaxHeight)
	}
}

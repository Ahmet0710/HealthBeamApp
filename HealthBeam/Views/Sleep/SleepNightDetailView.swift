import SwiftUI
import HealthKit
struct SleepNightDetailView: View {
	let analysis: DailySleepAnalysis
	@State private var selectedPeriod: SleepStagePeriod?
	@State private var heartRateData: [HKQuantitySample] = []
	private var sortedPeriods: [SleepStagePeriod] {
		analysis.stagePeriods.sorted { $0.startDate < $1.startDate }
	}
	private var sleepInterval: DateInterval? {
		guard let first = sortedPeriods.first, let last = sortedPeriods.last else {
			return nil
		}
		return DateInterval(start: first.startDate, end: last.endDate)
	}
	var body: some View {
		VStack(spacing: 0) {
			VStack {
				Text(analysis.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
					.font(.title3.bold())
					.foregroundStyle(.primary)
				Text("Sleep Analysis")
					.foregroundStyle(.secondary)
			}
			.padding()

			Divider()

			ScrollView {
				VStack(alignment: .leading, spacing: 24) {
					VStack(alignment: .leading, spacing: 8) {
						Text("Timeline")
							.font(.headline)
						SleepTimelineGraph(periods: sortedPeriods, totalDuration: analysis.totalInBedTime) { tappedPeriod in
							if selectedPeriod?.id == tappedPeriod?.id {
								selectedPeriod = nil
							} else {
								selectedPeriod = tappedPeriod
							}
						}
						HStack {
							Text(formatTime(sortedPeriods.first?.startDate))
							Spacer()
							Text(formatTime(sortedPeriods.last?.endDate))
						}
						.font(.caption)
						.foregroundColor(.secondary)
					}
					if let period = selectedPeriod {
						SleepPeriodDetailView(period: period)
							.transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
					}
					VStack(alignment: .leading, spacing: 8) {
						Text("Breakdown")
							.font(.headline)
						if analysis.totalAsleepTime > 0 {
							VStack(spacing: 12) {
								SleepStageStatView(stage: .deep, duration: analysis.duration(of: .deep), percentage: analysis.duration(of: .deep) / analysis.totalAsleepTime)
								SleepStageStatView(stage: .rem, duration: analysis.duration(of: .rem), percentage: analysis.duration(of: .rem) / analysis.totalAsleepTime)
								SleepStageStatView(stage: .light, duration: analysis.duration(of: .light), percentage: analysis.duration(of: .light) / analysis.totalAsleepTime)
								SleepStageStatView(stage: .awake, duration: analysis.duration(of: .awake), percentage: analysis.duration(of: .awake) / analysis.totalAsleepTime)
							}
							.padding()
							.background(Color(uiColor: .secondarySystemGroupedBackground))
							.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
						} else {
							Text("No sleep stages recorded.")
								.font(.subheadline)
								.foregroundColor(.secondary)
								.padding()
								.frame(maxWidth: .infinity)
								.background(Color(uiColor: .secondarySystemGroupedBackground))
								.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
						}
					}
					VStack(alignment: .leading, spacing: 8) {
						Text("Heart Rate During Sleep")
							.font(.headline)
						if !heartRateData.isEmpty {
							HeartRateChartView(samples: heartRateData)
								.padding()
								.background(Color(uiColor: .secondarySystemGroupedBackground))
								.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
						} else {
							HStack {
								Spacer()
								ProgressView()
								Spacer()
							}
							.padding()
							.frame(height: 150)
							.background(Color(uiColor: .secondarySystemGroupedBackground))
							.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
						}
					}
				}
				.padding()
				.animation(.spring(), value: selectedPeriod)
			}
		}
		.task(id: analysis.id) {
			if let interval = sleepInterval {
				self.heartRateData = await HealthKitManager.shared.fetchHeartRateDuring(startDate: interval.start, endDate: interval.end)
			}
		}
	}

	private func formatTime(_ date: Date?) -> String {
		guard let date = date else { return "N/A" }
		return date.formatted(date: .omitted, time: .shortened)
	}
}

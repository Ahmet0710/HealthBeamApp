import SwiftUI
struct SleepGoalCardView: View {
	@Binding var sleepGoal: TimeInterval
	let lastNightDuration: TimeInterval
	private var goalProgress: Double {
		guard sleepGoal > 0 else { return 0 }
		return min(lastNightDuration / sleepGoal, 1.0)
	}
	private var goalHoursBinding: Binding<Double> {
		Binding<Double>(
			get: {
				return self.sleepGoal / 3600
			},
			set: { newHourValue in
				self.sleepGoal = newHourValue * 3600
			}
		)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			Text("Sleep Goal")
				.font(.caption.bold())
				.kerning(0.5)
				.foregroundColor(.secondary)
			HStack(spacing: 24) {
				ZStack {
					CircularProgressView(progress: goalProgress, color: .teal, lineWidth: 12)
					Text(String(format: "%.0f%%", goalProgress * 100))
						.font(.title3.bold())
						.foregroundColor(.teal)
				}
				.frame(width: 100, height: 100)
				VStack(alignment: .leading) {
					Text("Your Goal: \(formatDuration(sleepGoal))")
						.font(.headline)
					Text("Last Night: \(formatDuration(lastNightDuration))")
						.font(.subheadline)
						.foregroundColor(.secondary)
					Stepper(
						"\(goalHoursBinding.wrappedValue, specifier: "%.1f") hours",
						value: goalHoursBinding,
						in: 4...12,
						step: 0.5
					)
					.padding(.top, 8)
				}
			}
		}
		.padding(20)
		.frame(maxWidth: .infinity, alignment: .leading)
		.frame(minHeight: 240)
		.background(Color(uiColor: .secondarySystemGroupedBackground))
		.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
	}

	private func formatDuration(_ duration: TimeInterval) -> String {
		let hours = Int(duration) / 3600
		let minutes = (Int(duration) % 3600) / 60
		return "\(hours)h \(minutes)m"
	}
}

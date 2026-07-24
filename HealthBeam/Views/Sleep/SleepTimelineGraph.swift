import SwiftUI
struct SleepTimelineGraph: View {
	let periods: [SleepStagePeriod]
	let totalDuration: TimeInterval
	let onSelectPeriod: (SleepStagePeriod?) -> Void
	var body: some View {
		GeometryReader { geometry in
			Canvas { context, size in
				guard totalDuration > 0 else { return }
				var currentX: CGFloat = 0
				let height = size.height
				for period in periods {
					let periodWidth = (period.duration / totalDuration) * size.width
					let rect = CGRect(x: currentX, y: 0, width: periodWidth, height: height)
					context.fill(Path(rect), with: .color(period.type.color))
					currentX += periodWidth
				}
			}
			.gesture(
				DragGesture(minimumDistance: 0)
					.onEnded { value in
						let selectedPeriod = findPeriod(at: value.location.x, canvasWidth: geometry.size.width)
						onSelectPeriod(selectedPeriod)
					}
			)
		}
		.frame(height: 40)
		.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
	}
	private func findPeriod(at locationX: CGFloat, canvasWidth: CGFloat) -> SleepStagePeriod? {
		guard totalDuration > 0 && canvasWidth > 0 else { return nil }
		var currentX: CGFloat = 0
		for period in periods {
			let periodWidth = (period.duration / totalDuration) * canvasWidth
			if locationX >= currentX && locationX < (currentX + periodWidth) {
				return period
			}
			currentX += periodWidth
		}
		return nil
	}
}

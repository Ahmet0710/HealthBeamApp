import SwiftUI
struct SleepSummaryCardView: View {
	let iconName: String
	let iconColor: Color
	let title: String
	let mainValue: String
	let subtitle: String?
	let detail: String?
	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			HStack(spacing: 8) {
				Image(systemName: iconName)
					.font(.subheadline.weight(.semibold))
					.foregroundColor(iconColor)
					.frame(width: 20, height: 20)
					.background(iconColor.opacity(0.15))
					.clipShape(Circle())
				Text(title.uppercased())
					.font(.caption.bold())
					.kerning(0.5)
					.foregroundColor(.secondary)
			}
			Text(mainValue)
				.font(.system(size: 32, weight: .bold, design: .rounded))
				.foregroundColor(.primary)
				.lineLimit(1)
				.minimumScaleFactor(0.8)
			if let subtitle = subtitle {
				Text(subtitle)
					.font(.subheadline)
					.foregroundColor(.gray)
			}
			if let detail = detail {
				Text(detail)
					.font(.footnote)
					.foregroundColor(.secondary)
					.padding(.top, 2)
			}
		}
		.padding(16)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(Color(uiColor: .secondarySystemGroupedBackground))
		.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
	}
}

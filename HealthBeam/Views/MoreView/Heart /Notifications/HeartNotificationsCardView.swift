import SwiftUI
struct HeartNotificationCardView: View {

    let summary: HeartNotificationSummary
    let range: NotificationTimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text(summary.type.title)
                .font(.headline)

            Text(range.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Text("\(summary.count) events")
                .font(.largeTitle.bold())

            Text(summary.type.subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 18)
        )
    }
}

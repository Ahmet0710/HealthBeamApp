import SwiftUI
struct NotificationRowView: View {

    let summary: HeartNotificationSummary

    var body: some View {
        HStack(spacing: 14) {

            Image(systemName: summary.type.icon)
                .font(.title2)
                .foregroundStyle(summary.type.color)

            VStack(alignment: .leading, spacing: 4) {
                Text(summary.type.title)
                    .font(.headline)

                Text(summary.type.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(summary.count)")
                .font(.title2.bold())
        }
        .padding()
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

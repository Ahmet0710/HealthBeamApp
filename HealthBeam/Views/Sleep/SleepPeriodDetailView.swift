import SwiftUI
struct SleepPeriodDetailView: View {
    let period: SleepStagePeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(period.type.color)
                    .frame(width: 12, height: 12)
                Text(period.type.rawValue)
                    .font(.headline)
            }
			HStack(alignment: .firstTextBaseline) {
                Text(formatDuration(period.duration))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Spacer()
                Text("\(formatTime(period.startDate)) - \(formatTime(period.endDate))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60
        if hours > 0 {
            return "\(hours)h \(minutes - (hours * 60))m"
        }
        return "\(minutes)m"
    }
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        return date.formatted(date: .omitted, time: .shortened)
    }
}

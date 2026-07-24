import SwiftUI
struct SleepStageStatView: View {
    let stage: SleepStage
    let duration: TimeInterval
    let percentage: Double
    var body: some View {
        HStack {
            Circle()
                .fill(stage.color)
                .frame(width: 12, height: 12)
            Text(stage.rawValue)
                .font(.headline)
            Spacer()
            Text(formatDuration(duration))
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(String(format: "%.0f%%", percentage * 100))
                .font(.subheadline.bold())
                .frame(width: 50, alignment: .trailing)
        }
    }
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

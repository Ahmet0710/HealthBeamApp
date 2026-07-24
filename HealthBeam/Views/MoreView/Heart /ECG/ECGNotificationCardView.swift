import SwiftUI
import HealthKit

struct ECGNotificationCardView: View {
    let entry: ECGEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Electrocardiogram (ECG)")
                .font(.headline)
                .foregroundStyle(.white)
            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(entry.classificationName)
                    .font(.title2.bold())
                    .foregroundStyle(classificationColor)
                if let hr = entry.averageHeartRate {
                    Text("\(Int(hr)) BPM")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            Text("Recorded on Apple Watch")
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

    private var classificationColor: Color {
        switch entry.classification {
        case .sinusRhythm:
            return .green
        case .atrialFibrillation:
            return .orange
        default:
            return .white
        }
    }
}

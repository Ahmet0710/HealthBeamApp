import SwiftUI

struct ECGRowView: View {
    let entry: ECGEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("ECG", systemImage: "waveform.path.ecg")
                    .font(.headline)
                    .foregroundStyle(.red)
                Spacer()
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                VStack(alignment: .leading) {
                    Text(entry.classificationName)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    if let hr = entry.averageHeartRate {
                        Text("\(Int(hr)) BPM Average")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

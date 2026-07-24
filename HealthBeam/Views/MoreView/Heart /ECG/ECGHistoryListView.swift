import SwiftUI
import HealthKit

struct ECGHistoryListView: View {
    let entries: [ECGEntry]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(entries) { entry in
                NavigationLink {
                    ECGDetailView(entry: entry)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date.formatted(date: .long, time: .omitted))
                                .font(.body.bold())
                            Text(entry.date.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(entry.classificationName)
                                .font(.subheadline.bold())
                                .foregroundStyle(color(for: entry.classification))
                            if let hr = entry.averageHeartRate {
                                Text("\(Int(hr)) BPM")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("ECG History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func color(for classification: HKElectrocardiogram.Classification) -> Color {
        switch classification {
        case .sinusRhythm:
            return .green
        case .atrialFibrillation:
            return .orange
        case .inconclusiveHighHeartRate, .inconclusiveLowHeartRate, .inconclusiveOther, .inconclusivePoorReading:
            return .blue
        default:
            return .gray
        }
    }
}

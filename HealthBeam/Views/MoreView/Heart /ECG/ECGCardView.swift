import SwiftUI
import HealthKit

struct ECGCardView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var entries: [ECGEntry] = []
    @State private var isLoading = false
    @State private var showHistory = false
    let themeColor = Color.red

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title2)
                Text("Electrocardiogram (ECG)")
                    .font(.headline.bold())
                Spacer()
            }
            .padding()
            .foregroundStyle(.white)
            .background(themeColor.gradient)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("\(entries.count)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(themeColor)
                        Text("recordings")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider()

                Text("ECGs recorded on Apple Watch show the electrical activity of your heart.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !entries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Recordings")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        ForEach(entries.prefix(3)) { entry in
                            NavigationLink {
                                ECGDetailView(entry: entry)
                            } label: {
                                ecgRow(entry)
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }

                        if entries.count > 3 {
                            Button {
                                showHistory = true
                            } label: {
                                Text("Load All")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(themeColor.opacity(0.1))
                                    .cornerRadius(10)
                                    .foregroundStyle(themeColor)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear { load() }
        .sheet(isPresented: $showHistory) {
            ECGHistoryListView(entries: entries)
        }
    }

    private func ecgRow(_ entry: ECGEntry) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.classificationName)
                    .font(.subheadline.bold())
                    .foregroundStyle(entry.classification == .sinusRhythm ? .green : .orange)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let hr = entry.averageHeartRate {
                Text("\(Int(hr)) BPM")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func load() {
        Task {
            isLoading = true
            let result = await healthKitManager.fetchECGEntries(limit: 50)
            await MainActor.run {
                entries = result
                isLoading = false
            }
        }
    }
}


//             ecgEntries = MockECG.sampleEntries


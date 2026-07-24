import SwiftUI
struct HeartEventHistoryView: View {
    let title: String
    let events: [HeartRateEvent]
    let color: Color
    let icon: String
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(events) { event in
                    HStack {
                        // TARİH VE SAAT
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.startDate.formatted(date: .long, time: .omitted))
                                .font(.body.bold())
                            Text(event.startDate.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // SAĞDAKİ DEĞER (Alert veya BPM)
                        HStack(spacing: 4) {
                            if event.averageBPM > 0 {
                                Text("\(Int(event.averageBPM)) bpm")
                            } else {
                                Text("Alert")
                            }
                            Image(systemName: icon)
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.1), in: Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

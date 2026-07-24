import SwiftUI
import HealthKit

struct LowCardioFitnessCardView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    var entry: HeartNotificationEntry? = nil
    
    @State private var range: NotificationTimeRange = .last6Months
    @State private var events: [HeartRateEvent] = []
    @State private var isLoading = false
    @State private var showHistory = false
    
    let themeColor = Color.teal

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "figure.run.circle.fill").font(.title2)
                Text("Low Cardio Fitness").font(.headline.bold())
                Spacer()
            }
            .padding().foregroundStyle(.white).background(themeColor.gradient)

            VStack(alignment: .leading, spacing: 16) {
                
                HStack(alignment: .firstTextBaseline) {
                    if let _ = entry {
                        Text("1").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(themeColor)
                        Text("alert").font(.headline).foregroundStyle(.secondary)
                    } else {
                        if isLoading { ProgressView() } else {
                            Text("\(events.count)").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(themeColor)
                            Text("alerts").font(.headline).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                
                Divider()
                Text("Notifications when your VO2 max falls into the low range for your age and sex.")
                    .font(.caption).foregroundStyle(.secondary)
                
                HStack {
                    Text("Range").font(.caption.bold()).foregroundStyle(.secondary)
                    Spacer()
                    Picker("Range", selection: $range) { ForEach(NotificationTimeRange.allCases) { Text($0.title).tag($0) } }
                    .tint(themeColor)
                }
                .padding(12).background(Color.black.opacity(0.05)).cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 8) {
                    if let demoEntry = entry {
                        Text("Recent Alerts").font(.caption.bold()).foregroundStyle(.secondary).padding(.top, 4)
                        HStack {
                            VStack(alignment: .leading) {
                                Text(demoEntry.date.formatted(date: .abbreviated, time: .omitted)).font(.subheadline.bold())
                                Text(demoEntry.date.formatted(date: .omitted, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Text(demoEntry.value) // "Low"
                                Image(systemName: "exclamationmark.circle.fill")
                            }
                            .font(.caption.bold()).foregroundStyle(themeColor)
                            .padding(.horizontal, 8).padding(.vertical, 4).background(themeColor.opacity(0.1), in: Capsule())
                        }.padding(.vertical, 4)
                        Divider()
                    } else if !events.isEmpty {
                        Text("Recent Alerts").font(.caption.bold()).foregroundStyle(.secondary).padding(.top, 4)
                        ForEach(events.prefix(3)) { event in eventRow(event); Divider() }
                        if events.count > 3 {
                            Button { showHistory = true } label: {
                                Text("Load All").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8).background(themeColor.opacity(0.1)).cornerRadius(10).foregroundStyle(themeColor)
                            }.padding(.top, 8)
                        }
                    }
                }
            }
            .padding().background(.ultraThinMaterial)
        }
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear { if entry == nil { load() } }
        .onChange(of: range) { if entry == nil { load() } }
        .sheet(isPresented: $showHistory) { HeartEventHistoryView(title: "Cardio Fitness History", events: events, color: themeColor, icon: "figure.run.circle.fill") }
    }

    private func eventRow(_ event: HeartRateEvent) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.startDate.formatted(date: .abbreviated, time: .omitted)).font(.subheadline.bold())
                Text(event.startDate.formatted(date: .omitted, time: .shortened)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) { Text("Low VO2 Max"); Image(systemName: "exclamationmark.circle.fill") }
            .font(.caption.bold()).foregroundStyle(themeColor)
            .padding(.horizontal, 8).padding(.vertical, 4).background(themeColor.opacity(0.1), in: Capsule())
        }.padding(.vertical, 4)
    }

    private func load() {
        Task {
            isLoading = true
            let result = await healthKitManager.fetchLowCardioFitnessEvents(range: range)
            await MainActor.run { events = result; isLoading = false }
        }
    }
}

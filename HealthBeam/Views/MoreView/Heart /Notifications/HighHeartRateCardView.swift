import SwiftUI
import HealthKit

struct HighHeartRateCardView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    // Dışarıdan gelen veri (Demo)
    var entry: HeartNotificationEntry? = nil
    
    @State private var range: NotificationTimeRange = .last6Months
    @State private var events: [HeartRateEvent] = []
    @State private var isLoading = false
    @State private var showHistory = false
    
    let themeColor = Color.red

    var body: some View {
        VStack(spacing: 0) {
            // HEADER (Sabit)
            HStack {
                Image(systemName: "arrow.up.heart.fill").font(.title2)
                Text("High Heart Rate").font(.headline.bold())
                Spacer()
            }
            .padding().foregroundStyle(.white).background(themeColor.gradient)

            // BODY
            VStack(alignment: .leading, spacing: 16) {
                
                // 1. SAYAÇ ALANI (Demo ise '1', Gerçek ise 'events.count')
                HStack(alignment: .firstTextBaseline) {
                    if let _ = entry {
                        // Demo Modu Sayacı
                        Text("1")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(themeColor)
                        Text("event").font(.headline).foregroundStyle(.secondary)
                    } else {
                        // Gerçek Mod Sayacı
                        if isLoading { ProgressView() } else {
                            Text("\(events.count)")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(themeColor)
                            Text("events").font(.headline).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                
                Divider()
                
                // 2. AÇIKLAMA YAZISI (Sabit)
                Text("Notifications from Apple Watch when your heart rate was unexpectedly high.")
                    .font(.caption).foregroundStyle(.secondary)
                
                // 3. ARALIK SEÇİCİ (Sabit)
                HStack {
                    Text("Range").font(.caption.bold()).foregroundStyle(.secondary)
                    Spacer()
                    Picker("Range", selection: $range) {
                        ForEach(NotificationTimeRange.allCases) { Text($0.title).tag($0) }
                    }
                    .tint(themeColor)
                }
                .padding(12).background(Color.black.opacity(0.05)).cornerRadius(12)
                
                // 4. LİSTE ALANI
                VStack(alignment: .leading, spacing: 8) {
                    if let demoEntry = entry {
                        // --- DEMO VERİSİ VARSA BUNU GÖSTER ---
                        Text("Recent Alerts").font(.caption.bold()).foregroundStyle(.secondary).padding(.top, 4)
                        
                        // Demo Satırı
                        HStack {
                            VStack(alignment: .leading) {
                                Text(demoEntry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline.bold())
                                Text(demoEntry.date.formatted(date: .omitted, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            // Veri Değeri (Örn: 128 BPM)
                            HStack(spacing: 4) {
                                Text(demoEntry.value)
                                Image(systemName: "bell.fill")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(themeColor)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(themeColor.opacity(0.1), in: Capsule())
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                        
                    } else if !events.isEmpty {
                        // --- GERÇEK VERİ VARSA LİSTEYİ GÖSTER ---
                        Text("Recent Alerts").font(.caption.bold()).foregroundStyle(.secondary).padding(.top, 4)
                        
                        ForEach(events.prefix(3)) { event in
                            eventRow(event)
                            Divider()
                        }
                        
                        if events.count > 3 {
                            Button { showHistory = true } label: {
                                Text("Load All")
                                    .font(.headline).frame(maxWidth: .infinity)
                                    .padding(.vertical, 8).background(themeColor.opacity(0.1))
                                    .cornerRadius(10).foregroundStyle(themeColor)
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
        .sheet(isPresented: $showHistory) {
            HeartEventHistoryView(title: "High Heart Rate History", events: events, color: themeColor, icon: "arrow.up.heart.fill")
        }
    }
    
    // Gerçek Veri Satırı
    private func eventRow(_ event: HeartRateEvent) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.bold())
                Text(event.startDate.formatted(date: .omitted, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Text("Alert")
                Image(systemName: "bell.fill")
            }
            .font(.caption.bold()).foregroundStyle(themeColor)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(themeColor.opacity(0.1), in: Capsule())
        }
        .padding(.vertical, 4)
    }

    private func load() {
        Task {
            isLoading = true
            let result = await healthKitManager.fetchHighHeartRateEvents(range: range)
            await MainActor.run { events = result; isLoading = false }
        }
    }
}

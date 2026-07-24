import SwiftUI
import HealthKit

struct LowHeartRateCardView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    // Dışarıdan gelen veri (Demo Modu için)
    var entry: HeartNotificationEntry? = nil
    
    @State private var range: NotificationTimeRange = .last6Months
    @State private var events: [HeartRateEvent] = []
    @State private var isLoading = false
    @State private var showHistory = false
    
    let themeColor = Color.blue

    var body: some View {
        VStack(spacing: 0) {
            // 1. HEADER (Başlık Alanı)
            HStack {
                Image(systemName: "arrow.down.heart.fill").font(.title2)
                Text("Low Heart Rate").font(.headline.bold())
                Spacer()
            }
            .padding()
            .foregroundStyle(.white)
            .background(themeColor.gradient)

            // 2. İÇERİK ALANI
            VStack(alignment: .leading, spacing: 16) {
                
                // --- SAYAÇ (Counter) ---
                HStack(alignment: .firstTextBaseline) {
                    if let _ = entry {
                        // Demo Modu: Sabit "1" göster
                        Text("1")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(themeColor)
                        Text("event")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    } else {
                        // Gerçek Mod: Yükleniyor veya Gerçek Sayı
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("\(events.count)")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(themeColor)
                            Text("events")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                
                Divider()
                
                // AÇIKLAMA
                Text("Notifications from Apple Watch when your heart rate was unexpectedly low.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // RANGE PICKER (Aralık Seçici)
                HStack {
                    Text("Range")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("Range", selection: $range) {
                        ForEach(NotificationTimeRange.allCases) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .tint(themeColor)
                }
                .padding(12)
                .background(Color.black.opacity(0.05))
                .cornerRadius(12)
                
                // --- LİSTE ALANI ---
                VStack(alignment: .leading, spacing: 8) {
                    
                    // DURUM A: DEMO VERİSİ VARSA
                    if let demoEntry = entry {
                        Text("Recent Alerts")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                        
                        // Demo Satırı
                        HStack {
                            VStack(alignment: .leading) {
                                Text(demoEntry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline.bold())
                                Text(demoEntry.date.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            // Değer (Örn: 42 BPM)
                            HStack(spacing: 4) {
                                Text(demoEntry.value)
                                Image(systemName: "bell.fill")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(themeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(themeColor.opacity(0.1), in: Capsule())
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                    }
                    // DURUM B: GERÇEK VERİ VARSA
                    else if !events.isEmpty {
                        Text("Recent Alerts")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                        
                        // İlk 3 kayıt
                        ForEach(events.prefix(3)) { event in
                            eventRow(event)
                            Divider()
                        }
                        
                        // "Hepsini Yükle" Butonu
                        if events.count > 3 {
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
        // Eğer demo verisi YOKSA gerçek veriyi yükle
        .onAppear {
            if entry == nil { load() }
        }
        .onChange(of: range) {
            if entry == nil { load() }
        }
        .sheet(isPresented: $showHistory) {
            HeartEventHistoryView(
                title: "Low Heart Rate History",
                events: events,
                color: themeColor,
                icon: "arrow.down.heart.fill"
            )
        }
    }
    
    // Tekrar eden satır tasarımı (Gerçek veri için)
    private func eventRow(_ event: HeartRateEvent) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.bold())
                Text(event.startDate.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Text("Alert")
                Image(systemName: "bell.fill")
            }
            .font(.caption.bold())
            .foregroundStyle(themeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(themeColor.opacity(0.1), in: Capsule())
        }
        .padding(.vertical, 4)
    }

    private func load() {
        Task {
            isLoading = true
            let result = await healthKitManager.fetchLowHeartRateEvents(range: range)
            await MainActor.run {
                events = result
                isLoading = false
            }
        }
    }
}

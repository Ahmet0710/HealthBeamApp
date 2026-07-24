import SwiftUI
import Charts
import HealthKit

struct ECGDetailView: View {
    let entry: ECGEntry
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var allData: [ECGPoint] = []
    @State private var isLoading = true
    @State private var showReader = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                
                if isLoading {
                    ProgressView("Processing ECG...")
                        .padding(.top, 40)
                } else if allData.isEmpty {
                    // Veri yoksa gösterilecek ekran
                    ContentUnavailableView("No Signal Available", systemImage: "waveform.path.ecg.rectangle")
                } else {
                    // Grafik Doluysa Burası Çalışır
                    ECGChartView(signals: allData)
                        .frame(height: 300)
                        .onTapGesture {
                            showReader = true
                        }
                    
                    Text("Tap the chart to view in detail")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.top, 4)
                    
                    HStack {
                        Text("25 mm/s")
                        Text("10 mm/mV")
                        Text("Lead I")
                        Spacer()
                        Text("Apple Watch Record")
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("ECG Report")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Sayfa açıldığında veriyi yükle
            await loadAndProcessData()
        }
        .fullScreenCover(isPresented: $showReader) {
            ECGInteractiveReaderView(data: allData, date: entry.date)
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.classificationName)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Text(entry.date.formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let hr = entry.averageHeartRate {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(Int(hr))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                    Text("BPM")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - KRİTİK VERİ YÜKLEME FONKSİYONU
    private func loadAndProcessData() async {
        // 1. DEMO MODU KONTROLÜ
        if AppReviewManager.shared.isDemoMode {
            print("📈 ECG Detail: Demo modu için sinüs dalgası oluşturuluyor...")
            
            // Simüle edilmiş 30 saniyelik veri üret
            // Entry içindeki BPM değerini kullan, yoksa 72 varsay.
            let simulatedBPM = entry.averageHeartRate ?? 72.0
            let mockWaveform = mockECGs.generateSinusRhythmWaveform(duration: 30.0, heartRate: simulatedBPM)
            
            // UI Güncellemesi (Main Actor)
            await MainActor.run {
                self.allData = mockWaveform
                self.isLoading = false
            }
            return // Fonksiyondan çık, HealthKit'e gitme.
        }
        
        // 2. GERÇEK VERİ AKIŞI
        guard let sample = entry.sample else {
            print("⚠️ ECG Detail: Sample verisi yok (Nil).")
            await MainActor.run { self.isLoading = false }
            return
        }
        
        let rawData = await healthKitManager.fetchECGWaveform(for: sample)
        let processedData = rawData.map { measurement in
            return ECGPoint(time: measurement.time, voltage: measurement.voltage)
        }
        
        await MainActor.run {
            self.allData = processedData
            self.isLoading = false
        }
    }
}

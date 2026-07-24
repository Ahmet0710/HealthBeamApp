import SwiftUI
import HealthKit

struct HeartSummaryView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    // UI State
    @State private var ecgEntries: [ECGEntry] = []
    @State private var heartEntries: [HeartEntry] = []
    @State private var bloodPressureEntries: [BloodPressureEntry] = []
    @State private var afibEntries: [AFibWeeklyEntry] = []
    
    // ✅ Bildirimleri Türüne Göre Saklayan Sözlük
    @State private var mockNotifications: [HeartNotificationType: HeartNotificationEntry] = [:]
    
    @State private var selectedRange: HeartTimeRange = .month
    @State private var displayDate = Date()
    @State private var isLoading = false
    
    // Demo Mode Kontrolü
    private var isDemoMode: Bool {
        return AppReviewManager.shared.isDemoMode
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    rangePicker
                    dateNavigator

                    // 1. KALP METRİKLERİ
                    VStack(spacing: 16) {
                        ForEach(HeartMetric.allCases) { metric in
                            NavigationLink {
                                HeartDetailView(metric: metric)
                            } label: {
                                HeartRowView(metric: metric, entries: entries(for: metric))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !bloodPressureEntries.isEmpty {
                        BloodPressureCardView(entries: bloodPressureEntries, range: selectedRange, referenceDate: displayDate)
                    }
                    
                    // 2. AFIB GEÇMİŞİ
                    if !afibEntries.isEmpty {
                        AFibHistoryCardView(entries: afibEntries, range: selectedRange)
                    }

                    // 3. EKG OKUMALARI
                    if ecgEntries.first != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ECG Readings")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                            ECGCardView()
                        }
                    }
                    
                    // 4. BİLDİRİMLER (Notifications)
                    // ✅ ORİJİNAL UI YAPISI KORUNDU
                    // Her karta ilgili Mock Veri parametre olarak geçiliyor.
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notifications")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .padding(.top, 10)
                        
                        HighHeartRateCardView(entry: mockNotifications[.highHeartRate])
                        LowHeartRateCardView(entry: mockNotifications[.lowHeartRate])
                        IrregularRhythmCardView(entry: mockNotifications[.irregularRhythm])
                        LowCardioFitnessCardView(entry: mockNotifications[.lowCardioFitness])
                        SleepApneaCardView(entry: mockNotifications[.sleepApnea])
                    }
                    .padding(.bottom, 40)
                }
                .padding()
            }
            .background(
                LinearGradient(colors: [Color.red.opacity(0.6), Color.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            )
            .navigationTitle("Heart")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear { Task { await fetchData() } }
        .onChange(of: selectedRange) { _, _ in Task { await fetchData() } }
        .onChange(of: displayDate) { _, _ in Task { await fetchData() } }
    } // body sonu

    // MARK: - Helper Views
    private var rangePicker: some View {
        Picker("Range", selection: $selectedRange) {
            ForEach(HeartTimeRange.allCases) { range in
                Text(range.localizedTitle).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .colorScheme(.dark)
    }

    private var dateNavigator: some View {
        HStack {
            Button { changeDate(by: -1) } label: {
                Image(systemName: "chevron.left").font(.title3.bold()).foregroundStyle(.white)
            }
            Spacer()
            Text(dateLabel).font(.headline).foregroundStyle(.white)
            Spacer()
            Button { changeDate(by: 1) } label: {
                Image(systemName: "chevron.right").font(.title3.bold()).foregroundStyle(.white)
                    .opacity(isFuture ? 0.3 : 1.0)
            }
            .disabled(isFuture)
        }
        .padding()
        .background(.white.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Functions
    private func fetchData() async {
        isLoading = true
        
        // ---------------------------------------------------------
        // 1. DEMO MODU: MOCK VERİLERİ YÜKLE
        // ---------------------------------------------------------
        if isDemoMode {
            print("❤️ Heart View: Demo Modu Aktif.")
            let calendar = Calendar.current
            
            // A. Kalp Metriklerini Çek
            let allMockEntries = MockHeart.sampleHeartEntries
            let filteredHeartEntries = allMockEntries.filter { entry in
                return isDate(entry.date, inRange: selectedRange, of: displayDate, calendar: calendar)
            }
            
            // B. EKG Mock Verisi
           
            
            // C. AFib Mock Verisi (MockAFib dosyası varsa oradan, yoksa manuel)
            // (MockAFib.swift dosyasının eklendiğini varsayıyorum)
            let mockAFib: [AFibWeeklyEntry] = MockAFib.sampleEntries
            
            // ✅ D. BİLDİRİM MOCK VERİSİ (Sözlük Doldurma)
            var newNotifications: [HeartNotificationType: HeartNotificationEntry] = [:]
            for type in HeartNotificationType.allCases {
                if let entry = MockNotifications.getMockData(for: type) {
                    newNotifications[type] = entry
                }
            }
            
            // UI Güncelleme
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            await MainActor.run {
                self.heartEntries = filteredHeartEntries.sorted { $0.date < $1.date }
                self.ecgEntries = mockECGs.sampleEntries
                self.afibEntries = mockAFib
                self.mockNotifications = newNotifications // Bildirimleri güncelle
                self.bloodPressureEntries = []
                self.isLoading = false
            }
            return
        }
        
        // ---------------------------------------------------------
        // 2. GERÇEK HEALTHKIT VERİSİ
        // ---------------------------------------------------------
        if !healthKitManager.isAuthorized { try? await healthKitManager.requestAuthorization() }
        
        async let fetchedEcgs = healthKitManager.fetchECGEntries()
        async let fetchedBp = healthKitManager.fetchBloodPressureEntries(range: selectedRange, referenceDate: displayDate)
        async let fetchedAfib = healthKitManager.fetchAFibWeeklyEntries(referenceDate: displayDate)
        
        var heart: [HeartEntry] = []
        for metric in HeartMetric.allCases {
            let entries = (selectedRange == .year)
                ? await healthKitManager.fetchYearlyHeartMetric(metric: metric, year: displayDate)
                : await healthKitManager.fetchHeartEntries(metric: metric, range: selectedRange, referenceDate: displayDate)
            heart.append(contentsOf: entries)
        }
        
        let ecgs = await fetchedEcgs
        let bp = await fetchedBp
        let afib = await fetchedAfib
        
        await MainActor.run {
            self.heartEntries = heart.sorted { $0.date < $1.date }
            self.bloodPressureEntries = bp
            self.afibEntries = afib
            self.ecgEntries = ecgs
            self.mockNotifications = [:] // Gerçek veride mock veriyi temizle
            self.isLoading = false
        }
    }
    
    // Yardımcı: Tarih Aralığı Kontrolü
    private func isDate(_ date: Date, inRange range: HeartTimeRange, of referenceDate: Date, calendar: Calendar) -> Bool {
        switch range {
        case .day:
            return calendar.isDate(date, inSameDayAs: referenceDate)
        case .week:
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return false }
            return weekInterval.contains(date)
        case .month:
            guard let monthInterval = calendar.dateInterval(of: .month, for: referenceDate) else { return false }
            return monthInterval.contains(date)
        case .year:
            guard let yearInterval = calendar.dateInterval(of: .year, for: referenceDate) else { return false }
            return yearInterval.contains(date)
        }
    }

    private func entries(for metric: HeartMetric) -> [HeartEntry] {
        heartEntries.filter { $0.metric == metric }
    }

    private func changeDate(by value: Int) {
        let component: Calendar.Component
        switch selectedRange {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }
        if let newDate = Calendar.current.date(byAdding: component, value: value, to: displayDate) {
            displayDate = newDate
        }
    }

    private var isFuture: Bool {
        let calendar = Calendar.current
        switch selectedRange {
        case .day: return calendar.isDateInToday(displayDate)
        default: return displayDate >= Date()
        }
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        switch selectedRange {
        case .day: formatter.dateStyle = .medium; return formatter.string(from: displayDate)
        case .week:
            let start = displayDate
            let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        case .month: formatter.dateFormat = "MMMM yyyy"; return formatter.string(from: displayDate)
        case .year: formatter.dateFormat = "yyyy"; return formatter.string(from: displayDate)
        }
    }
}

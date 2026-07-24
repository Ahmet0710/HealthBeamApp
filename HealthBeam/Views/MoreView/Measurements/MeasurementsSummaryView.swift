import SwiftUI
import HealthKit
import Combine

enum TimeRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    var id: String { rawValue }

    var localizedTitle: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

struct MeasurementsSummaryView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var allEntries: [MeasurementEntry] = []
    @State private var isShowingAddSheet = false
    @State private var selectedTimeRange: TimeRange = .month
    @State private var displayDate = Date()
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    timeRangePicker
                    dateNavigatorView

                    let entriesToDisplay = processedEntries(
                        for: allEntries,
                        range: selectedTimeRange,
                        displayDate: displayDate
                    )

                    measurementList(for: entriesToDisplay)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.orange.opacity(0.5), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Measurements")
            .toolbarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isShowingAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddMeasurementView { newEntry in
                    // Demo modunda manuel ekleme yapılırsa listeye ekle ama kaydetme (VM içinde engellenmeli ama burada UI'da görünmesi yeterli)
                    allEntries.insert(newEntry, at: 0)
                    allEntries.sort { $0.date > $1.date }
                }
            }
            .onAppear {
                Task { await requestAndReadData() }
                
                // HealthKit güncellemelerini dinle (Sadece demo kapalıyken anlamlı)
                healthKitManager.healthDataDidUpdate
                    .receive(on: DispatchQueue.main)
                    .sink { _ in
                        Task { await readHealthKitData() }
                    }
                    .store(in: &cancellables)
            }
            .onDisappear {
                cancellables.removeAll()
            }
            .onChange(of: selectedTimeRange) {
                displayDate = Date()
            }
        }
    }

    private func requestAndReadData() async {
        // MARK: - Demo Modu Kontrolü (İzin İstemeyi Atla)
        if AppReviewManager.shared.isDemoMode {
            await readHealthKitData()
            return
        }
        
        if !healthKitManager.isAuthorized { try? await healthKitManager.requestAuthorization() }
        await readHealthKitData()
    }

    @MainActor
    private func readHealthKitData() async {
        // MARK: - Demo Modu: Mock Veri Yükle
        if AppReviewManager.shared.isDemoMode {
            print("📏 Measurements Demo Modu: Mock veriler yükleniyor...")
            allEntries = MockMeasurements.sampleMeasurements.sorted { $0.date > $1.date }
            return
        }
        
        // Gerçek Veri
        let fetched = await healthKitManager.fetchHealthMeasurements()
        allEntries = fetched.sorted { $0.date > $1.date }
    }

    private var timeRangePicker: some View {
        Picker("Time interval", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases) { range in
                Text(range.localizedTitle).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .colorScheme(.dark)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var dateNavigatorView: some View {
        HStack {
            Button { moveDate(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
            Text(dateNavigatorTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Button { moveDate(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private func measurementList(for entries: [MeasurementEntry]) -> some View {
        VStack(spacing: 12) {
            // Sadece verisi olan tipleri göster veya Demo modunda hepsini gösterip boş olanları filtrele
            ForEach(MeasurementType.allCases) { type in
                let typeEntries = entries.filter { $0.type == type }
                
                // Eğer bu tipte veri varsa göster (Mock veride bazı tipler boş olabilir)
                if !typeEntries.isEmpty {
                    NavigationLink {
                        MeasurementDetailView(type: type, allEntries: $allEntries, onDelete: deleteEntries)
                    } label: {
                        MeasurementRowView(type: type, entries: typeEntries)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dateNavigatorTitle: String {
        let calendar = Calendar.current
        switch selectedTimeRange {
        case .day: return displayDate.formatted(.dateTime.weekday(.wide).day().month().year())
        case .week:
            let interval = calendar.dateInterval(of: .weekOfYear, for: displayDate)!
            return "\(interval.start.formatted(.dateTime.day().month())) – \(interval.end.addingTimeInterval(-1).formatted(.dateTime.day().month().year()))"
        case .month: return displayDate.formatted(.dateTime.month(.wide).year())
        case .year: return displayDate.formatted(.dateTime.year())
        }
    }

    private func moveDate(by value: Int) {
        let component: Calendar.Component
        switch selectedTimeRange {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }
        displayDate = Calendar.current.date(byAdding: component, value: value, to: displayDate) ?? displayDate
    }

    private func deleteEntries(ids: Set<UUID>) {
        // Demo modunda silme işlemi sadece listeden kaldırır, kalıcı olmaz.
        allEntries.removeAll { ids.contains($0.id) }
    }
}

private func processedEntries(for allEntries: [MeasurementEntry], range: TimeRange, displayDate: Date) -> [MeasurementEntry] {
    let calendar = Calendar.current
    let interval: DateInterval
    switch range {
    case .day: interval = calendar.dateInterval(of: .day, for: displayDate)!
    case .week: interval = calendar.dateInterval(of: .weekOfYear, for: displayDate)!
    case .month: interval = calendar.dateInterval(of: .month, for: displayDate)!
    case .year: interval = calendar.dateInterval(of: .year, for: displayDate)!
    }
    return allEntries.filter { interval.contains($0.date) }
}

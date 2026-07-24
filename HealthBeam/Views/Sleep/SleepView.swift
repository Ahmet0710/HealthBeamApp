import SwiftUI
import Charts
import HealthKit

// MARK: - Card Style Modifier
struct HB5CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.6))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
    }
}

extension View {
    func hb5CardStyle() -> some View {
        modifier(HB5CardStyle())
    }
}

// MARK: - Main Sleep View
struct SleepView: View {
    @StateObject private var viewModel = SleepViewModel()
    @AppStorage("sleepGoal") private var sleepGoal: TimeInterval = 8 * 3600
    
    // Trend Offsets
    @State private var trendWeekOffset: Int = 0
    @State private var trendMonthOffset: Int = 0
    @State private var trendYearOffset: Int = 0
    
    // Trend Metrics
    @State private var selectedWeeklyTrendMetric: HealthDataType = .sleepScore
    @State private var selectedMonthlyTrendMetric: HealthDataType = .sleepScore
    @State private var selectedYearlyTrendMetric: HealthDataType = .sleepScore

    var body: some View {
        NavigationStack {
            ZStack {
                // Arka Plan: HealthBeam 5.0 Gradient
                LinearGradient(
                    colors: [Color.indigo.opacity(0.3), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // Header
                        HStack {
                            Text("Sleep")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [ .indigo.opacity(1)], startPoint: .leading, endPoint: .trailing)
                                )
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)

                        // --- İÇERİK KONTROLÜ ---
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 400)
                                .tint(.indigo)
                        } else if let lastNight = viewModel.lastNight {
                            
                            // 1. YENİ DASHBOARD (Tüm özet veriler tek kartta)
                            UnifiedSleepDashboardCard(
                                lastNight: lastNight,
                                sleepGoal: $sleepGoal
                            )
                            .padding(.horizontal)

                            // 2. Weekly Summary
                            weeklySummarySection()
                            
                            if viewModel.isLoadingExtendedMetrics {
                                loadingInsightsCard
                            } else {
                                // 3. Trends (Weekly, Monthly, Yearly)
                                VStack(spacing: 24) {
                                    trendsSection()
                                    monthlyTrendsSection()
                                    yearlyTrendsSection()
                                }
                                
                                // 4. Comparison
                                comparisonSection()
                            }
                            
                            // Alt Boşluk
                            Color.clear.frame(height: 50)
                            
                        } else {
                            // ✅ VERİ YOKSA (Empty State) - Güncellendi
                            emptyStateView()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .safeAreaPadding(.top, 8)
            .task { await viewModel.fetchDataIfNeeded() }
        }
        .preferredColorScheme(.dark)
        // MARK: - Logic Handlers
        .onChange(of: trendWeekOffset) { _, newOffset in
            viewModel.processTrendData(for: newOffset, metric: selectedWeeklyTrendMetric)
        }
        .onChange(of: selectedWeeklyTrendMetric) { _, newMetric in
            viewModel.processTrendData(for: trendWeekOffset, metric: newMetric)
        }
        .onChange(of: trendMonthOffset) { _, newOffset in
            viewModel.processMonthlyTrendData(for: newOffset, metric: selectedMonthlyTrendMetric)
        }
        .onChange(of: selectedMonthlyTrendMetric) { _, newMetric in
            viewModel.processMonthlyTrendData(for: trendMonthOffset, metric: newMetric)
        }
        .onChange(of: trendYearOffset) { _, newOffset in
            viewModel.processYearlyTrendData(for: newOffset, metric: selectedYearlyTrendMetric)
        }
        .onChange(of: selectedYearlyTrendMetric) { _, newMetric in
            viewModel.processYearlyTrendData(for: trendYearOffset, metric: newMetric)
        }
    }

    private var loadingInsightsCard: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(.indigo)
                .scaleEffect(1.1)
            Text("Loading sleep insights")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            Text("Charts and comparison metrics are still being prepared in the background.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal)
        .hb5CardStyle()
        .padding(.horizontal)
    }
    
    // MARK: - 1. Unified Dashboard Card
    struct UnifiedSleepDashboardCard: View {
        let lastNight: DailySleepAnalysis
        @Binding var sleepGoal: TimeInterval
        
        private var goalProgress: Double {
            guard sleepGoal > 0 else { return 0 }
            return min(lastNight.totalAsleepTime / sleepGoal, 1.0)
        }
        
        private var goalHoursBinding: Binding<Double> {
            Binding<Double>(
                get: { self.sleepGoal / 3600 },
                set: { self.sleepGoal = $0 * 3600 }
            )
        }

        var body: some View {
            VStack(spacing: 0) {
                // Üst Kısım: Ana Uyku Süresi ve Hedef Halkası
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LAST NIGHT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .kerning(1)
                        
                        Text(formatDuration(lastNight.totalAsleepTime))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .indigo.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Text(lastNight.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Goal Ring
                    ZStack {
                        CircularProgressView(progress: goalProgress, color: .indigo, lineWidth: 8)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "bed.double.fill")
                            .font(.title3)
                            .foregroundStyle(.indigo.gradient)
                    }
                }
                .padding(20)
                
                Divider().background(.white.opacity(0.1))
                
                // Alt Kısım: İstatistikler ve Goal Stepper
                HStack(spacing: 0) {
                    // Score
                    StatItem(
                        icon: "gauge.medium",
                        iconColor: .purple,
                        title: String(localized: "Score"),
                        value: "\(lastNight.sleepScore)",
                        subValue: "/ 100"
                    )
                    
                    Divider().frame(height: 40).background(.white.opacity(0.1))
                    
                    // Efficiency
                    StatItem(
                        icon: "chart.pie.fill",
                        iconColor: .teal,
                        title: String(localized: "Efficiency"),
                        value: "\(Int(lastNight.sleepEfficiency * 100))%",
                        subValue: nil
                    )
                    
                    Divider().frame(height: 40).background(.white.opacity(0.1))
                    
                    // Goal Setting
                    VStack(spacing: 2) {
                        Text("GOAL")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(goalHoursBinding.wrappedValue))h")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                        
                        Stepper("", value: goalHoursBinding, in: 4...12, step: 0.5)
                            .labelsHidden()
                            .scaleEffect(0.7)
                            .frame(height: 20)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.2))
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .hb5CardStyle()
        }
        
        private func formatDuration(_ duration: TimeInterval) -> String {
            let hours = Int(duration) / 3600
            let minutes = (Int(duration) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }
    }
    
    struct StatItem: View {
        let icon: String
        let iconColor: Color
        let title: String
        let value: String
        let subValue: String?
        
        var body: some View {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundStyle(iconColor)
                    Text(title.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    if let sub = subValue {
                        Text(sub)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 2. Weekly Summary Section
    private func weeklySummarySection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Weekly Overview", systemImage: "chart.bar.doc.horizontal")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Tarih Gezintisi
                HStack(spacing: 16) {
                    Button(action: { viewModel.showPreviousWeek() }) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    Button(action: { viewModel.showNextWeek() }) {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.bold))
                            .foregroundStyle(viewModel.weekOffset == 0 ? .gray.opacity(0.3) : .secondary)
                    }
                    .disabled(viewModel.weekOffset == 0)
                }
            }
            
            // Tarih Aralığı
            Text(viewModel.weekDateRangeString)
                .font(.subheadline)
                .foregroundStyle(.indigo.opacity(0.8))
                .fontWeight(.semibold)
            
            // YENİ İNTERAKTİF GRAFİK
            InteractiveWeeklySleepChart(
                analyses: viewModel.weeklyChartData,
                selectedAnalysis: $viewModel.selectedAnalysisForSheet
            )
        }
        .padding(20)
        .hb5CardStyle()
        .padding(.horizontal)
    }
    
    // MARK: - 3. Trend Sections (Container Logic)
    private func trendsSection() -> some View {
        trendSectionContainer(
            title: String(localized: "Weekly Trends"),
            icon: "chart.xyaxis.line",
            dateRangeString: viewModel.trendChartDateRangeString,
            isPreviousDisabled: viewModel.isPreviousTrendButtonDisabled,
            isNextDisabled: viewModel.isNextTrendButtonDisabled,
            chartData: viewModel.trendChartData.map { ChartDataPoint(date: $0.date, value: $0.value, totalSleepDurationMinutes: 0, timeInBedMinutes: 0, lightSleepDurationMinutes: 0) },
            selectedMetric: $selectedWeeklyTrendMetric,
            onPrevious: { trendWeekOffset += 1 },
            onNext: { trendWeekOffset -= 1 }
        )
    }
    
    private func monthlyTrendsSection() -> some View {
        trendSectionContainer(
            title: String(localized: "Monthly Trends"),
            icon: "calendar.badge.clock",
            dateRangeString: viewModel.monthlyTrendChartDateRangeString,
            isPreviousDisabled: viewModel.isPreviousMonthTrendButtonDisabled,
            isNextDisabled: viewModel.isNextMonthTrendButtonDisabled,
            chartData: viewModel.monthlyTrendChartData.map { ChartDataPoint(date: $0.date, value: $0.value, totalSleepDurationMinutes: 0, timeInBedMinutes: 0, lightSleepDurationMinutes: 0) },
            selectedMetric: $selectedMonthlyTrendMetric,
            onPrevious: { trendMonthOffset += 1 },
            onNext: { trendMonthOffset -= 1 }
        )
    }
    
    private func yearlyTrendsSection() -> some View {
        trendSectionContainer(
            title: String(localized: "Yearly Trends"),
            icon: "clock.arrow.circlepath",
            dateRangeString: viewModel.yearlyTrendChartDateRangeString,
            isPreviousDisabled: viewModel.isPreviousYearTrendButtonDisabled,
            isNextDisabled: viewModel.isNextYearTrendButtonDisabled,
            chartData: viewModel.yearlyTrendChartData.map { ChartDataPoint(date: $0.date, value: $0.value, totalSleepDurationMinutes: 0, timeInBedMinutes: 0, lightSleepDurationMinutes: 0) },
            selectedMetric: $selectedYearlyTrendMetric,
            onPrevious: { trendYearOffset += 1 },
            onNext: { trendYearOffset -= 1 }
        )
    }
    
    @ViewBuilder
    private func trendSectionContainer(title: String, icon: String, dateRangeString: String, isPreviousDisabled: Bool, isNextDisabled: Bool, chartData: [ChartDataPoint], selectedMetric: Binding<HealthDataType>, onPrevious: @escaping () -> Void, onNext: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Label(title, systemImage: icon)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Spacer()
                
                // Mini Navigation
                HStack(spacing: 12) {
                    Button(action: onPrevious) { Image(systemName: "chevron.left").bold() }
                        .disabled(isPreviousDisabled)
                        .foregroundStyle(isPreviousDisabled ? .gray.opacity(0.3) : .secondary)
                    
                    Text(dateRangeString)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 80)
                        .multilineTextAlignment(.center)
                    
                    Button(action: onNext) { Image(systemName: "chevron.right").bold() }
                        .disabled(isNextDisabled)
                        .foregroundStyle(isNextDisabled ? .gray.opacity(0.3) : .secondary)
                }
            }
            
            // Content
            VStack(spacing: 16) {
                // Şık Metrik Seçici
                Menu {
                    Picker("Metric", selection: selectedMetric) {
                        ForEach(HealthDataType.allCases.filter { $0.color != .red && $0.color != .yellow && $0.color != .green }) { metric in
                            Text(metric.localizedTitle).tag(metric)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedMetric.wrappedValue.localizedTitle)
                            .font(.subheadline.bold())
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(selectedMetric.wrappedValue.color)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(selectedMetric.wrappedValue.color.opacity(0.15))
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Grafik
                let isYearly = title == String(localized: "Yearly Trends")
                if !chartData.isEmpty {
                    TrendsChartView(data: chartData, metric: selectedMetric.wrappedValue, isYearly: isYearly)
                } else {
                    ProgressView().frame(height: 200, alignment: .center)
                }
            }
        }
        .padding(20)
        .hb5CardStyle()
        .padding(.horizontal)
        .animation(.default, value: chartData)
    }
    
    // MARK: - 4. Comparison Section
    private func comparisonSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("Compare Analysis", systemImage: "arrow.left.arrow.right")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { viewModel.showPreviousComparisonWeek() }) {
                        Image(systemName: "chevron.left").bold()
                    }
                    .foregroundStyle(.secondary)
                    
                    Button(action: { viewModel.showNextComparisonWeek() }) {
                        Image(systemName: "chevron.right").bold()
                    }
                    .disabled(viewModel.isAtCurrentComparisonWeek)
                    .foregroundStyle(viewModel.isAtCurrentComparisonWeek ? .gray.opacity(0.3) : .secondary)
                }
            }
            
            Text(viewModel.comparisonDateRangeString)
                .font(.subheadline)
                .foregroundStyle(.indigo.opacity(0.8))
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                // Metric 1 Seçimi
                HStack {
                    Circle().fill(viewModel.selectedMetric1.color).frame(width: 8, height: 8)
                    Menu {
                        Picker("Metric 1", selection: $viewModel.selectedMetric1) {
                            ForEach(HealthDataType.allCases) { metric in Text(metric.localizedTitle).tag(metric) }
                        }
                    } label: {
                        Text(viewModel.selectedMetric1.localizedTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.down").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.bottom, 8)

                // Karşılaştırma Grafiği
                ComparisonChartView(
                    data1: viewModel.chartData1,
                    metric1: viewModel.selectedMetric1,
                    data2: viewModel.chartData2,
                    metric2: viewModel.selectedMetric2
                )
                
                // Metric 2 Seçimi
                HStack {
                    Circle().fill(viewModel.selectedMetric2.color).frame(width: 8, height: 8)
                    Menu {
                        Picker("Metric 2", selection: $viewModel.selectedMetric2) {
                            ForEach(HealthDataType.allCases) { metric in Text(metric.localizedTitle).tag(metric) }
                        }
                    } label: {
                        Text(viewModel.selectedMetric2.localizedTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.down").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .hb5CardStyle()
        .padding(.horizontal)
        .animation(.default, value: viewModel.chartData1)
    }
    
    // MARK: - ✅ Updated Empty State with Motivation Cards
    private func emptyStateView() -> some View {
        VStack(spacing: 24) {            
            // Motivasyon Kartları
            VStack(spacing: 16) {
                MotivationCardView(
                    icon: "moon.zzz.fill",
                    iconColor: .indigo,
                    title: String(localized: "Good sleep, good life"),
                    description: String(localized: "Time to build healthy sleep habits"),
                    items: [
                        String(localized: "Prioritize your rest"),
                        String(localized: "Every night counts"),
                        String(localized: "Start your sleep journey now")
                    ]
                )
                MotivationCardView(
                    icon: "bed.double.fill",
                    iconColor: .cyan,
                    title: String(localized: "Rest well"),
                    description: String(localized: "Create routines that promote quality sleep"),
                    items: [
                        String(localized: "Limit screen time"),
                        String(localized: "Keep a consistent schedule"),
                        String(localized: "Make your bedroom cozy")
                    ]
                )
                MotivationCardView(
                    icon: "cloud.moon.fill",
                    iconColor: .blue,
                    title: String(localized: "Sleep smarter"),
                    description: String(localized: "Track and improve your nightly rest"),
                    items: [
                        String(localized: "Monitor your patterns"),
                        String(localized: "Adjust for better sleep"),
                        String(localized: "Wake up refreshed")
                    ]
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views

struct TrendsChartView: View {
    let data: [ChartDataPoint]
    let metric: HealthDataType
    let isYearly: Bool
    var body: some View {
        let chart = Chart(data) { point in
            let yValue = point.value > 0 ? point.value : 0
            if isYearly {
                BarMark(
                    x: .value("Date", point.date, unit: .month),
                    y: .value(metric.localizedTitle, yValue)
                )
                .foregroundStyle(metric.color.gradient)
                .cornerRadius(4)
            } else if metric == .sleepScore || metric == .sleepEfficiency {
                LineMark(x: .value("Date", point.date), y: .value(metric.localizedTitle, yValue))
                    .foregroundStyle(metric.color)
                    .interpolationMethod(.catmullRom)
                AreaMark(x: .value("Date", point.date), y: .value(metric.localizedTitle, yValue))
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [metric.color.opacity(0.4), .clear]), startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
            } else {
                BarMark(x: .value("Date", point.date), y: .value(metric.localizedTitle, yValue))
                    .foregroundStyle(metric.color.gradient)
                    .cornerRadius(4)
            }
        }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine()
                    if let yValue = value.as(Double.self) {
                        AxisValueLabel(formatYAxisLabel(for: yValue))
                    }
                }
            }
            .frame(height: 200)
        if isYearly {
            chart
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        if value.as(Date.self) != nil {
                            AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
                        }
                    }
                }
        } else {
            chart
                .chartXAxis(.hidden)
        }
    }
    private func formatYAxisLabel(for value: Double) -> String {
        switch metric {
            case .sleepDuration, .timeInBed, .deepSleep, .remSleep, .lightSleep:
                let hours = value / 3600
                if hours < 1 { return "\(Int(value / 60))m" }
                return String(format: "%.0fh", hours)
            default:
                return String(format: "%.0f", value)
        }
    }
}

struct ComparisonChartView: View {
    let data1: [MetricDataPoint]
    let metric1: HealthDataType
    let data2: [MetricDataPoint]
    let metric2: HealthDataType

    var body: some View {
        VStack(spacing: 0) {
            if !data1.isEmpty {
                singleChart(data: data1, metric: metric1, isInverted: false)
            }
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.5))
                .padding(.horizontal)
            if !data2.isEmpty {
                singleChart(data: data2, metric: metric2, isInverted: true)
            }
        }
        .frame(height: 250)
    }

    private func singleChart(data: [MetricDataPoint], metric: HealthDataType, isInverted: Bool) -> some View {
        let yValues = data.map { $0.value }
        let maxY = yValues.max() ?? 1
        return Chart(data) { point in
            let yValue = isInverted ? -point.value : point.value
            LineMark(x: .value("Date", point.date, unit: .day), y: .value(metric.rawValue, yValue))
                .foregroundStyle(metric.color)
                .interpolationMethod(.catmullRom)
            AreaMark(x: .value("Date", point.date, unit: .day), y: .value(metric.rawValue, yValue))
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [metric.color.opacity(0.4), .clear]), startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: isInverted ? -maxY * 1.1...0 : 0...maxY * 1.1)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                if let yValue = value.as(Double.self) {
                    let labelValue = isInverted ? abs(yValue) : yValue
                    AxisValueLabel(formatYAxisLabel(for: labelValue, metric: metric))
                }
            }
        }
        .chartXAxis(.hidden)
    }

    private func formatYAxisLabel(for value: Double, metric: HealthDataType) -> String {
        switch metric {
            case .sleepDuration, .timeInBed, .deepSleep, .remSleep, .lightSleep:
                let hours = value / 3600
                if hours < 1 { return "\(Int(value / 60))m" }
                return String(format: "%.0fh", hours)
            default:
                return String(format: "%.0f", value)
        }
    }
}

// MARK: - NEW: Motivation Card View Component
private struct MotivationCardView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let items: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle().fill(iconColor.opacity(0.13)).frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(iconColor.opacity(0.7))
            }
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundColor(.white)
            Text(description)
                .font(.callout.weight(.medium))
                .foregroundColor(.gray.opacity(0.95))
            Divider().background(Color.white.opacity(0.09)).padding(.trailing, 32)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    Text("• " + item)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.09).blendMode(.plusLighter))
                .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 10)
        )
    }
}

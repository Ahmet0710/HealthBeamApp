import SwiftUI
import Charts

struct HeartRowView: View {
    let metric: HeartMetric
    let entries: [HeartEntry]

    // İletişim Durumları (Interaction State)
    @State private var selectedDate: Date?
    @State private var selectedValue: Double?

    private var accentColor: Color { Self.color(for: metric) }
    
    // Gradient: Grafik dolgusu
    private var accentGradient: LinearGradient {
        LinearGradient(colors: [accentColor, accentColor.opacity(0.3)], startPoint: .top, endPoint: .bottom)
    }

    private var sortedEntries: [HeartEntry] {
        entries.sorted { $0.date < $1.date }
    }

    private var lastEntry: HeartEntry? {
        sortedEntries.last
    }

    private var chartData: [HeartChartDataPoint] {
        sortedEntries.map {
            HeartChartDataPoint(
                date: $0.date,
                HeartRate: $0.value
            )
        }
    }

    private var yAxisDomain: ClosedRange<Double>? {
        let values = chartData.map { $0.HeartRate }
        guard let minValue = values.min(), let maxValue = values.max() else { return nil }

        if minValue == maxValue {
            return (minValue - 5)...(maxValue + 5)
        }
        let padding = (maxValue - minValue) * 0.1
        return max(0, minValue - padding)...(maxValue + padding)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            chartView.frame(height: 150)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
        )
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
                Text(metric.localizedTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                if let date = selectedDate ?? lastEntry?.date {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .animation(.none, value: selectedDate)
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                if let entry = lastEntry {
                    let value = selectedValue ?? entry.value
                    Text("\(Int(value)) \(metric.unit)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(accentGradient)
                        .contentTransition(.numericText())
                } else {
                    Text("No Data")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Chart View
    @ViewBuilder
    private var chartView: some View {
        if chartData.isEmpty {
            VStack {
                Spacer()
                Text("No data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .background(Color.clear)
        } else {
            Chart(chartData) { point in
                // AreaMark
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.HeartRate)
                )
                .foregroundStyle(accentGradient.opacity(0.4))
                .interpolationMethod(.catmullRom)

                // LineMark
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.HeartRate)
                )
                .foregroundStyle(accentGradient)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: yAxisDomain ?? 0...200)
            
            // ✅ X EKSENİ AYARLARI (BEYAZ)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    // Dikey Kesik Çizgiler - Beyaz
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(.white.opacity(0.25))
                    
                    // Tarih Etiketleri - Beyaz
                    AxisValueLabel(format: .dateTime.day().month(), centered: true)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            // ✅ Y EKSENİ AYARLARI (BEYAZ)
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    // Yatay Çizgiler - Beyaz
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.25))
                    
                    // Değer Etiketleri - Beyaz
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            .chartPlotStyle { $0.clipped() }
            
            // Etkileşim Katmanları
            .chartOverlay { proxy in
                HeartChartInteractionOverlay(
                    proxy: proxy,
                    data: chartData,
                    selectedValue: $selectedValue,
                    selectedDate: $selectedDate
                )
            }
            .chartBackground { proxy in
                HeartChartInteractionBackground(
                    proxy: proxy,
                    color: accentColor,
                    selectedValue: selectedValue,
                    selectedDate: selectedDate
                )
            }
        }
    }
}

// MARK: - Colors
extension HeartRowView {
    static func color(for metric: HeartMetric) -> Color {
        switch metric {
        case .heartRate: return .red
        case .restingHeartRate: return .orange
        case .heartRateVariability: return .purple
        case .walkingHeartRate: return .blue
        case .cardioFitness: return .green
        case .cardioRecovery: return .pink
        }
    }
}

// MARK: - Interaction Components

private struct HeartChartInteractionOverlay: View {
    let proxy: ChartProxy
    let data: [HeartChartDataPoint]
    @Binding var selectedValue: Double?
    @Binding var selectedDate: Date?

    var body: some View {
        GeometryReader { geo in
            Rectangle().fill(.clear).contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if let plotFrame = proxy.plotFrame {
                                let x = value.location.x - geo[plotFrame].origin.x
                                if let date: Date = proxy.value(atX: x),
                                   let point = data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                    self.selectedDate = point.date
                                    self.selectedValue = point.HeartRate
                                }
                            }
                        }
                        .onEnded { _ in
                            self.selectedDate = nil
                            self.selectedValue = nil
                        }
                )
        }
    }
}

private struct HeartChartInteractionBackground: View {
    let proxy: ChartProxy
    let color: Color
    let selectedValue: Double?
    let selectedDate: Date?

    var body: some View {
        if let date = selectedDate, let value = selectedValue,
           let xPos = proxy.position(forX: date),
           let yPos = proxy.position(forY: value) {
            
            Rectangle()
                .fill(.white.opacity(0.6)) // Çizgi de beyaza yakın gri yapıldı
                .frame(width: 1, height: proxy.plotSize.height)
                .position(x: xPos, y: proxy.plotSize.height / 2)
            
            Circle()
                .strokeBorder(.white, lineWidth: 2) // Çerçeve beyaz
                .background(Circle().fill(color))
                .frame(width: 12, height: 12)
                .position(x: xPos, y: yPos)
        }
    }
}

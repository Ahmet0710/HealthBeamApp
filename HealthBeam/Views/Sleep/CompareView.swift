import SwiftUI
import Charts
struct CompareView: View {
    @StateObject private var viewModel = CompareViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerView
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(height: 600)
                    } else {
                        VStack(alignment: .leading) {
                            Text("Graph 1")
                                .font(.caption.bold()).foregroundStyle(.secondary)
                            Picker("Graph 1 Metric", selection: $viewModel.selectedMetric1) {
                                ForEach(HealthMetric.allCases) { metric in
                                    Text(metric.rawValue).tag(metric)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                            MetricChartView(
                                metric: viewModel.selectedMetric1,
                                data: viewModel.chartData1,
                                isReversed: false
                            )
                        }
                        Divider()
                        VStack(alignment: .leading) {
                            Text("Graph 2")
                                .font(.caption.bold()).foregroundStyle(.secondary)
                            Picker("Graph 2 Metric", selection: $viewModel.selectedMetric2) {
                                ForEach(HealthMetric.allCases) { metric in
                                    Text(metric.rawValue).tag(metric)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                            MetricChartView(
                                metric: viewModel.selectedMetric2,
                                data: viewModel.chartData2,
                                isReversed: true
                            )
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Compare")
            .navigationBarHidden(true)
            .task {
                await viewModel.fetchData()
            }
        }
    }
    private var headerView: some View {
        VStack(alignment: .leading) {
            Text("Compare Metrics")
                .font(.largeTitle.bold())
            Text(viewModel.dateRangeString)
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
struct MetricChartView: View {
    let metric: HealthMetric
    let data: [ChartDataPoint]
    var isReversed: Bool = false

    var body: some View {
        VStack {
            Chart(data) { point in
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value(metric.rawValue, isReversed ? -point.value : point.value)
                )
                .foregroundStyle(metric.color.gradient)
            }
            .frame(height: 250)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) {
                    AxisGridLine()
                    AxisTick()
                }
            }
            .overlay {
                if data.isEmpty {
                    ContentUnavailableView("No Data", systemImage: "chart.bar.xaxis.ascending.badge.clock")
                }
            }
            
            if isReversed {
                Text("Y axis has been reversed.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

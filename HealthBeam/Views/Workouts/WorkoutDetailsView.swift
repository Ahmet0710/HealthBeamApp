import SwiftUI
import HealthKit
import MapKit
import Charts
import Combine
struct WorkoutDetailsView: View {
    @StateObject private var viewModel: WorkoutDetailsViewModel
    @EnvironmentObject var measurementSystemManager: MeasurementSystemManager
    @State private var selectedTab: DetailTab = .overview

    init(workout: HKWorkout) {
        self._viewModel = StateObject(wrappedValue: WorkoutDetailsViewModel(workout: workout))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView.padding(.bottom)
                pickerView
                switch selectedTab {
                    case .overview:
                        OverviewTabView(viewModel: viewModel, measurementSystemManager: measurementSystemManager)
                    case .heartRate:
                        HeartRateTabView(viewModel: viewModel)
                }
            }
            .padding()
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(backgroundGradient)
        .task { await viewModel.loadWorkoutDetails() }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.activityType.icon).font(.system(size: 50, weight: .bold))
                .foregroundColor(viewModel.activityType.color).frame(width: 100, height: 100)
                .background(.white.opacity(0.1)).clipShape(Circle())
            Text(viewModel.activityType.displayName).font(.largeTitle.bold()).foregroundColor(.white)
            Text(viewModel.workout.startDate, style: .date).font(.title3).foregroundColor(.secondary)
        }
    }

    private var pickerView: some View {
        Picker("Details", selection: $selectedTab) {
            ForEach(DetailTab.allCases) { tab in Text(tab.localizedTitle).tag(tab) }
        }
        .pickerStyle(.segmented).padding(.bottom)
    }

    private var backgroundGradient: some View {
        LinearGradient(colors: [viewModel.activityType.color.opacity(0.3), .black.opacity(0.8)],
                       startPoint: .top, endPoint: .bottom
        ).ignoresSafeArea()
    }
}
enum DetailTab: String, CaseIterable, Identifiable {
    case overview = "Overview", heartRate = "Heart Rate"
    var id: String { self.rawValue }
    var localizedTitle: String {
        String(localized: LocalizedStringResource(stringLiteral: rawValue))
    }
}
struct OverviewTabView: View {
    @ObservedObject var viewModel: WorkoutDetailsViewModel
    @ObservedObject var measurementSystemManager: MeasurementSystemManager
    var body: some View {
        VStack(spacing: 24) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                MetricCardView(icon: "clock.fill", title: String(localized: "Duration"), value: viewModel.formattedDuration, color: .blue)
                MetricCardView(icon: "flame.fill", title: String(localized: "Calories"), value: viewModel.formattedCalories, color: .orange)
                MetricCardView(icon: "ruler.fill", title: String(localized: "Distance"), value: formattedDistance, color: .green)
                MetricCardView(icon: "timer", title: String(localized: "Average Pace"), value: formattedPace, color: .yellow)
            }
            if viewModel.totalElevationGain > 0 {
                MetricCardView(icon: "arrow.up.right.circle.fill", title: String(localized: "Elevation Gain"), value: String(format: "%.0f m", viewModel.totalElevationGain), color: .brown)
            }
            routeAndElevationSection
        }
    }

    private var formattedDistance: String {
        let meters = viewModel.workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        return MetricFormatter.formatDistance(meters, measurementSystem: measurementSystemManager.measurementSystem)
    }

    private var formattedPace: String {
        let meters = viewModel.workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        let durationMinutes = viewModel.workout.duration / 60
        return MetricFormatter.formatPace(distanceMeters: meters, durationMinutes: durationMinutes, measurementSystem: measurementSystemManager.measurementSystem)
    }
    @ViewBuilder
    private var routeAndElevationSection: some View {
        if viewModel.isLoadingDetails {
            ProgressView().frame(maxWidth: .infinity, minHeight: 300)
        } else if !viewModel.routeLocations.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Route & Elevation").font(.title2.bold()).foregroundColor(.white)
                Map {
                    MapPolyline(coordinates: viewModel.routeLocations.map { $0.coordinate })
                        .stroke(viewModel.activityType.color, lineWidth: 5)
                    if let startCoord = viewModel.routeLocations.first?.coordinate {
                        Annotation(String(localized: "Start"), coordinate: startCoord) {
                            Circle().fill(.green).frame(width: 10, height: 10).shadow(radius: 2)
                        }
                    }
                    if let endCoord = viewModel.routeLocations.last?.coordinate {
                        Annotation(String(localized: "End"), coordinate: endCoord) {
                            ZStack {
                                Circle().fill(.black).frame(width: 20, height: 20)
                                Image(systemName: "flag.checkered.2.crossed").font(.callout).foregroundColor(.white)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 250).cornerRadius(12)
                Text("Elevation").font(.headline.bold()).foregroundColor(.white).padding(.top)
                Chart {
                    ForEach(Array(viewModel.routeLocations.enumerated()), id: \.offset) { index, location in
                        LineMark(
                            x: .value("Distance", location.distance(from: viewModel.routeLocations.first!)),
                            y: .value("Elevation", location.altitude)
                        )
                        .foregroundStyle(Color.brown.gradient)
                    }
                }
                .chartXAxisLabel(String(localized: "Distance (m)")).chartYAxisLabel(String(localized: "Elevation (m)")).frame(height: 100)
            }
            .padding().backgroundCard()
        } else {
            EmptyView()
        }
    }
}
struct HeartRateTabView: View {
    @ObservedObject var viewModel: WorkoutDetailsViewModel
    @State private var selectedDate: Date? = nil
    var body: some View {
        VStack(spacing: 24) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                MetricCardView(icon: "heart.fill", title: String(localized: "Avg. Heart Rate"), value: viewModel.avgHeartRateBPM, color: .red)
                MetricCardView(icon: "bolt.heart.fill", title: String(localized: "Max Heart Rate"), value: viewModel.maxHeartRateBPM, color: .pink)
            }
            interactiveHeartRateChart
            heartRateZonesView
        }
    }
    private var interactiveHeartRateChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heart Rate Over Time").font(.title2.bold()).foregroundColor(.white)
            if viewModel.isLoadingDetails {
                ProgressView().frame(maxWidth: .infinity, minHeight: 150)
            } else if viewModel.heartRateData.isEmpty {
                Text("No heart rate data available.").foregroundColor(.secondary).frame(maxWidth: .infinity, minHeight: 150)
            } else {
                Chart {
                    ForEach(viewModel.heartRateData, id: \.uuid) { sample in
                        let bpm = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                        LineMark(x: .value("Time", sample.startDate), y: .value("BPM", bpm))
                            .foregroundStyle(viewModel.activityType.color.gradient).interpolationMethod(.catmullRom)
                    }
                    if let selectedDate {
                        RuleMark(x: .value("Selected", selectedDate, unit: .second))
                            .foregroundStyle(.white.opacity(0.5)).offset(y: -10).zIndex(-1)
                            .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit, y: .fit)) { annotationView }
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) }
                .frame(height: 150)
                .chartOverlay { proxy in
                    GeometryReader { innerProxy in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if let date: Date = proxy.value(atX: value.location.x) { selectedDate = date }
                                }
                                .onEnded { _ in selectedDate = nil })
                    }
                }
            }
        }
        .padding().backgroundCard()
    }
    @ViewBuilder private var annotationView: some View {
        if let selectedDate, let sample = viewModel.heartRateData.min(by: { abs($0.startDate.distance(to: selectedDate)) < abs($1.startDate.distance(to: selectedDate)) }) {
            let bpm = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
            Text(String(format: "%.0f BPM", bpm)).font(.headline.bold())
                .foregroundColor(viewModel.activityType.color).padding(8)
        }
    }
    private var heartRateZonesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time in Zones").font(.title2.bold()).foregroundColor(.white)
            if viewModel.isLoadingDetails {
                ProgressView().frame(maxWidth: .infinity)
            } else if viewModel.zoneDistribution.isEmpty {
                Text("Heart rate zones could not be calculated.").foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.zoneDistribution) { zoneInfo in ZoneBarView(zoneInfo: zoneInfo) }
                }
            }
        }
        .padding().backgroundCard()
    }
}
struct ZoneBarView: View {
    let zoneInfo: HeartRateZoneInfo
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(zoneInfo.zone.name).font(.caption.bold()).foregroundColor(zoneInfo.zone.color)
                Spacer()
                Text(zoneInfo.durationFormatted).font(.caption).foregroundColor(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.1))
                    Capsule().fill(zoneInfo.zone.color).frame(width: geometry.size.width * zoneInfo.percentage)
                }
            }.frame(height: 8)
        }
    }
}
struct MetricCardView: View {
    let icon: String, title: String, value: String, color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).font(.title2).foregroundColor(color)
                Spacer()
            }
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.title2.bold()).foregroundColor(.white)
                .minimumScaleFactor(0.7).lineLimit(1)
        }
        .padding().backgroundCard()
    }
}
struct BackgroundCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(.white.opacity(0.05)).cornerRadius(16)
    }
}
extension View {
    func backgroundCard() -> some View { self.modifier(BackgroundCardModifier()) }
}
struct StatCard<Content: View>: View {
    let title: String
    let color: Color
    let content: Content
    init(title: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.color = color
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            content
        }
        .padding()
        .backgroundCard()
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
extension HKWorkout {
    static func sample() async throws -> HKWorkout {
        let healthStore = HKHealthStore()
        let start = Date()
        let end = Date().addingTimeInterval(1800)
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: nil)
        try await builder.beginCollection(at: start)
        try await builder.endCollection(at: end)
        let _: [String: Any] = [HKMetadataKeyIndoorWorkout: false]
        let workout = try await builder.finishWorkout()
        guard let workout else { throw NSError(domain: "HKWorkoutSample", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create workout"]) }
        return workout
    }
}
struct Previewing {
    @MainActor
    struct WorkoutDetailsViewAsync: View {
        @State private var workout: HKWorkout? = nil
        @State private var error: Error? = nil
        var body: some View {
            Group {
                if let workout {
                    NavigationStack {
                        WorkoutDetailsView(workout: workout)
                            .environmentObject(MeasurementSystemManager())
                    }
                } else if let error {
                    Text("Failed to load workout sample: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ProgressView().onAppear {
                        Task {
                            do {
                                workout = try await HKWorkout.sample()
                            } catch {
                                self.error = error
                            }
                        }
                    }
                }
            }
        }
    }
}

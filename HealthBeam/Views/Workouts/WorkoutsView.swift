import SwiftUI
import Combine
import HealthKit

private struct WorkoutSectionCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.62))
                    .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private extension View {
    func workoutSectionCardStyle() -> some View {
        modifier(WorkoutSectionCardStyle())
    }
}

// MARK: - Metric Formatter
struct MetricFormatter {
    static func formatDistance(_ meters: Double, measurementSystem: MeasurementSystem) -> String {
        if measurementSystem == .Metric {
            return String(format: "%.2f km", meters / 1000)
        } else {
            let miles = meters / 1609.34
            return String(format: "%.2f mi", miles)
        }
    }

    static func formatPace(distanceMeters: Double, durationMinutes: Double, measurementSystem: MeasurementSystem) -> String {
        guard distanceMeters > 0 else { return "--" }
        if measurementSystem == .Metric {
            let km = distanceMeters / 1000
            let pace = durationMinutes / km
            let min = Int(pace)
            let sec = Int((pace - Double(min)) * 60)
            return String(format: "%d'%02d\"/km", min, sec)
        } else {
            let miles = distanceMeters / 1609.34
            let pace = durationMinutes / miles
            let min = Int(pace)
            let sec = Int((pace - Double(min)) * 60)
            return String(format: "%d'%02d\"/mi", min, sec)
        }
    }
}

// MARK: - Workout Card View
struct WorkoutCardView: View {
    let workout: Workout
    @EnvironmentObject var measurementSystemManager: MeasurementSystemManager

    private var categoryColor: Color {
        workout.tintColor
    }

    private func formattedTimeRange() -> String {
        let endDate = workout.startDate.addingTimeInterval(TimeInterval(workout.duration * 60))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let startString = formatter.string(from: workout.startDate)
        let endString = formatter.string(from: endDate)
        return "\(startString) - \(endString)"
    }

    @ViewBuilder
    private func metricChip(_ title: String, _ icon: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(color.opacity(0.16))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.20), lineWidth: 1)
                )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.14))
                        .frame(width: 52, height: 52)
                    Image(systemName: workout.iconName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(categoryColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.localizedType)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    Text(formattedTimeRange())
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            FlowLayout(spacing: 8) {
                if workout.totalDistance > 0 {
                    metricChip(String(localized: "Distance"), "figure.walk", MetricFormatter.formatDistance(workout.totalDistance, measurementSystem: measurementSystemManager.measurementSystem), .blue)
                }
                if workout.totalEnergyBurned > 0 {
                    metricChip(String(localized: "Calories"), "flame.fill", "\(Int(workout.totalEnergyBurned)) kcal", .red)
                }
                if workout.averageHeartRate > 0 {
                    metricChip(String(localized: "Heart Rate"), "heart.fill", "\(Int(workout.averageHeartRate)) bpm", .pink)
                }
                if workout.averagePace != "-" {
                    metricChip(String(localized: "Pace"), "timer", workout.totalDistance > 0 ? MetricFormatter.formatPace(distanceMeters: workout.totalDistance, durationMinutes: Double(workout.duration), measurementSystem: measurementSystemManager.measurementSystem) : "--", .yellow)
                }
            }
        }
        .padding(18)
        .workoutSectionCardStyle()
    }
}

// MARK: - Workouts View
struct WorkoutsView: View {
    @StateObject private var viewModel = WorkoutsViewModel()
    @State private var selectedWorkoutType: HKWorkoutActivityType?
    @State private var showingFilter = false
    @State private var showingAddWorkout = false
    @State private var selectedWorkoutForDetails: Workout? = nil
    @State private var navigateToStartWorkout = false

    @State private var selectedHKWorkout: HKWorkout? = nil
    @State private var loadingHKWorkout = false

    @EnvironmentObject private var measurementSystemManager: MeasurementSystemManager
    @EnvironmentObject var reviewManager: AppReviewManager

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .none
        return df
    }()

    private var workoutSectionsArray: [WorkoutDaySectionView] {
        groupedWorkouts.keys.sorted(by: >).map { date in
            WorkoutDaySectionView(
                date: date,
                workouts: groupedWorkouts[date] ?? [],
                dateFormatter: dateFormatter,
                viewModel: viewModel,
                onWorkoutTap: { workout in
                    showDetails(for: workout)
                }
            )
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        workoutsHeaderRow

                        if viewModel.isLoading {
                            loadingStateView
                        } else if filteredWorkouts.isEmpty {
                            emptyStateView
                        } else {
                            workoutSummaryCard

                            VStack(spacing: 18) {
                                ForEach(Array(workoutSectionsArray.enumerated()), id: \.element.date) { _, section in
                                    section
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
            }
            .safeAreaPadding(.top, 8)
            .safeAreaInset(edge: .bottom) {
                workoutActionInset
            }
            .onAppear {
                Task { await viewModel.requestAuthorizationAndFetch() }
            }
            .onChange(of: reviewManager.isDemoMode) { _, _ in
                Task { await viewModel.requestAuthorizationAndFetch() }
            }
            .sheet(isPresented: $showingFilter) {
                FilterSheetView(
                    workoutTypes: workoutTypes,
                    selectedType: $selectedWorkoutType,
                    isPresented: $showingFilter
                )
            }
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutView { newWorkout in
                    viewModel.addWorkout(newWorkout)
                    showingAddWorkout = false
                }
            }
            .sheet(item: $selectedWorkoutForDetails, onDismiss: {
                selectedHKWorkout = nil
                loadingHKWorkout = false
                selectedWorkoutForDetails = nil
            }) { _ in
                if loadingHKWorkout {
                    VStack(spacing: 16) {
                        ProgressView("Loading workout details...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                            .foregroundColor(.white)
                            .font(.title3)
                        Spacer()
                    }
                    .padding()
                } else if let hkWorkout = selectedHKWorkout {
                    WorkoutDetailsView(workout: hkWorkout)
                } else {
                    VStack(spacing: 16) {
                        Text("Could not find detailed workout data.")
                            .font(.title3)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $navigateToStartWorkout) {
                StartWorkoutView()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.red.opacity(0.26),
                    Color.orange.opacity(0.10),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.red.opacity(0.18))
                .blur(radius: 90)
                .frame(width: 300, height: 300)
                .offset(x: 140, y: -220)

            Circle()
                .fill(Color.orange.opacity(0.10))
                .blur(radius: 100)
                .frame(width: 280, height: 280)
                .offset(x: -120, y: 260)
        }
    }

    private var workoutsHeaderRow: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Workouts")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red.opacity(1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Move with intention and keep your momentum visible.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: { showingFilter = true }) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal)
    }

    private var workoutSummaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All Workouts")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(selectedWorkoutType?.displayName ?? String(localized: "All workout types"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(filteredWorkouts.count)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    statPill(title: String(localized: "Sessions"), value: "\(filteredWorkouts.count)", tint: .red)
                    statPill(title: String(localized: "Days"), value: "\(groupedWorkouts.count)", tint: .orange)
                    statPill(title: String(localized: "Filter"), value: selectedWorkoutType?.displayName ?? String(localized: "All"), tint: .pink)
                }

                VStack(spacing: 8) {
                    statPill(title: String(localized: "Sessions"), value: "\(filteredWorkouts.count)", tint: .red)
                    statPill(title: String(localized: "Days"), value: "\(groupedWorkouts.count)", tint: .orange)
                    statPill(title: String(localized: "Filter"), value: selectedWorkoutType?.displayName ?? String(localized: "All"), tint: .pink)
                }
            }
        }
        .padding(20)
        .workoutSectionCardStyle()
        .padding(.horizontal)
    }

    private var loadingStateView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.1)
            Text("Loading your workouts")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            Text("Pulling recent activity from HealthKit.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
        .padding(.horizontal, 24)
        .workoutSectionCardStyle()
        .padding(.horizontal)
    }

    private var workoutActionInset: some View {
        HStack {
            Spacer()
            actionMenu
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var actionMenu: some View {
        Menu {
            Button(action: { showingAddWorkout = true }) {
                Label("Add Workout", systemImage: "plus")
            }
            Button(action: { navigateToStartWorkout = true }) {
                Label("Start Workout", systemImage: "play.circle")
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 62, height: 62)
                .background(
                    Circle()
                        .fill(Color.red.opacity(0.25))
                        .background(Circle().fill(.ultraThinMaterial))
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        )
                )
                .clipShape(Circle())
                .shadow(color: .red.opacity(0.30), radius: 14, x: 0, y: 8)
        }
    }

    private func statPill(title: String, value: String, tint: Color) -> some View {
        WorkoutStatPill(title: title, value: value, tint: tint)
    }

    private var workoutTypes: [HKWorkoutActivityType] {
        Array(Set(viewModel.workouts.map(\.activityType))).sorted { $0.displayName < $1.displayName }
    }

    private var filteredWorkouts: [Workout] {
        guard let selectedWorkoutType else { return viewModel.workouts }
        return viewModel.workouts.filter { $0.activityType == selectedWorkoutType }
    }

    private var groupedWorkouts: [Date: [Workout]] {
        Dictionary(grouping: filteredWorkouts) {
            Calendar.current.startOfDay(for: $0.startDate)
        }
    }

    private func showDetails(for workout: Workout) {
        loadingHKWorkout = true
        selectedWorkoutForDetails = workout
        selectedHKWorkout = nil

        Task {
            let hkWorkouts = await HealthKitManager.shared.fetchWorkouts()
            let workoutStart = workout.startDate
            let workoutEnd = workout.startDate.addingTimeInterval(TimeInterval(workout.duration * 60))
            let matchedHKWorkout = hkWorkouts.first(where: { hk in
                let hkStart = hk.startDate
                let hkEnd = hk.endDate
                let startMatch = abs(hkStart.timeIntervalSince(workoutStart)) < 60
                let endMatch = abs(hkEnd.timeIntervalSince(workoutEnd)) < 60
                return startMatch && endMatch
            })

            await MainActor.run {
                selectedHKWorkout = matchedHKWorkout
                loadingHKWorkout = false
            }
        }
    }

    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.red.opacity(0.16))
                    .frame(width: 54, height: 54)
                    .overlay(
                        Image(systemName: "figure.run")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.red)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("No workouts yet")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Start moving, log a session, or import recent activity from HealthKit.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 12) {
                MotivationCardViews(
                    icon: "sparkles",
                    iconColor: .red,
                    title: NSLocalizedString("Great day to start", comment: ""),
                    description: NSLocalizedString("Never too late to move", comment: ""),
                    items: [
                        NSLocalizedString("Invest in yourself", comment: ""),
                        NSLocalizedString("Better every day", comment: ""),
                        NSLocalizedString("Hardest part is starting", comment: "")
                    ]
                )
                MotivationCardViews(
                    icon: "figure.walk",
                    iconColor: .blue,
                    title: NSLocalizedString("Small steps big change", comment: ""),
                    description: NSLocalizedString("Every step brings you closer", comment: ""),
                    items: [
                        NSLocalizedString("Move every day", comment: ""),
                        NSLocalizedString("Move forward, even if a little", comment: ""),
                        NSLocalizedString("Start today, you'll feel the difference", comment: "")
                    ]
                )
                MotivationCardViews(
                    icon: "target",
                    iconColor: .green,
                    title: NSLocalizedString("Focus on your goals", comment: ""),
                    description: NSLocalizedString("Focus is the key to success", comment: ""),
                    items: [
                        NSLocalizedString("Remember your goal", comment: ""),
                        NSLocalizedString("Celebrate your progress", comment: ""),
                        NSLocalizedString("Keep your motivation high!", comment: "")
                    ]
                )
            }
        }
        .padding(20)
        .workoutSectionCardStyle()
        .padding(.horizontal)
    }
}

// MARK: - Filter Sheet
struct FilterSheetView: View {
    let workoutTypes: [HKWorkoutActivityType]
    @Binding var selectedType: HKWorkoutActivityType?
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    selectedType = nil
                    isPresented = false
                }) {
                    HStack {
                        Text(String(localized: "All"))
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedType == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }

                ForEach(workoutTypes, id: \.self) { type in
                    Button(action: {
                        selectedType = type
                        isPresented = false
                    }) {
                        HStack {
                            Text(type.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Workout Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}

private struct WorkoutStatPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(tint)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Motivation Card View
private struct MotivationCardViews: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            Text(description)
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
            Divider()
                .background(Color.white.opacity(0.10))
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    Text("• " + item)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Workout Day Section
private struct WorkoutDaySectionView: View {
    let date: Date
    let workouts: [Workout]
    let dateFormatter: DateFormatter
    let viewModel: WorkoutsViewModel
    let onWorkoutTap: (Workout) -> Void

    @EnvironmentObject var measurementSystemManager: MeasurementSystemManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(dateFormatter.string(from: date))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ForEach(workouts) { workout in
                    Button(action: { onWorkoutTap(workout) }) {
                        WorkoutCardView(workout: workout)
                            .environmentObject(measurementSystemManager)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .workoutSectionCardStyle()
        .padding(.horizontal)
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: spacing) {
                content
            }
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
        }
    }
}

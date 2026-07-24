import SwiftUI
import HealthKit

private func localizedWorkoutAddLabel(_ value: String) -> String {
    String(localized: LocalizedStringResource(stringLiteral: value))
}

struct WorkoutPreviewCardView: View {
    let activityType: HKWorkoutActivityType
    let startDate: Date
    let durationMins: Int
    let calories: Double
    let distanceKm: Double
    let heartRate: Int
    let pace: String

    private var visuals: WorkoutVisuals {
        WorkoutVisuals.from(activityType: activityType)
    }

    private var categoryColor: Color {
        visuals.color
    }

    private func formattedTimeRange() -> String {
        let endDate = startDate.addingTimeInterval(TimeInterval(durationMins * 60))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        return "\(startString) - \(endString)"
    }

    @ViewBuilder
    private func metricChip(_ title: String, _ icon: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 7) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.subheadline)
            Text(value)
                .foregroundColor(.white)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(color)
        .clipShape(Capsule())
        .shadow(color: color.opacity(0.29), radius: 2, x: 0, y: 2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle().fill(categoryColor.opacity(0.13)).frame(width: 48, height: 48)
                    Image(systemName: visuals.safeSystemIcon)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.93))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(activityType.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                    Text(formattedTimeRange())
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.65))
                }
                Spacer()
            }
            VStack(alignment: .leading, spacing: 8) {
                if distanceKm > 0 {
                    metricChip(String(localized: "Distance"), "figure.walk", String(format: "%.2f km", distanceKm), .blue)
                }
                if calories > 0 {
                    metricChip(String(localized: "Calories"), "flame.fill", "\(Int(calories)) kcal", .red)
                }
                if heartRate > 0 {
                    metricChip(String(localized: "Heart Rate"), "heart.fill", "\(Int(heartRate)) bpm", .pink)
                }
                if pace != "-" {
                    metricChip(String(localized: "Pace"), "timer", pace, .yellow)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [categoryColor.opacity(0.33), categoryColor.opacity(0.19)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: categoryColor.opacity(0.21), radius: 14, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(categoryColor.opacity(0.27), lineWidth: 1.8)
                )
        )
        .padding(.vertical, 8)
    }
}
struct AddWorkoutView: View {
    enum Field: Hashable { case calories, distance, heartRate }

    var categoryColor: Color { WorkoutVisuals.from(activityType: selectedActivityType).color }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedActivityType: HKWorkoutActivityType = .running
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var calories: String = ""
    @State private var distance: String = ""
    @State private var heartRate: String = ""
    @FocusState private var focusedField: Field?
    @State private var isAutoFilling = false
    @State private var showingMetrics = false

    var onSave: ((Workout) -> Void)?
    let workoutTypes: [HKWorkoutActivityType] = [.running, .walking, .cycling, .rowing, .swimming, .hiking, .yoga, .traditionalStrengthTraining, .highIntensityIntervalTraining, .other]

    var isValid: Bool {
        guard endDate > startDate else { return false }
        let durationValue = endDate.timeIntervalSince(startDate) / 60
        guard durationValue > 0 else { return false }
        guard let caloriesValue = Double(calories), caloriesValue > 0 else { return false }
        if !distance.isEmpty {
            guard let distanceValue = Double(distance), distanceValue >= 0 else { return false }
        }
        if !heartRate.isEmpty {
            guard let heartRateValue = Int(heartRate), heartRateValue > 0 else { return false }
        }
        return true
    }

    func autoFillFromHealthApp() async {
        isAutoFilling = true
        defer { isAutoFilling = false }
        let healthStore = HKHealthStore()
        let start = startDate
        let end = endDate
        func sumQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit, options: HKStatisticsOptions) async -> Double? {
            guard let type = HKObjectType.quantityType(forIdentifier: id) else { return nil }
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { _, result, _ in
                    let value = result?.sumQuantity()?.doubleValue(for: unit)
                    continuation.resume(returning: value)
                }
                healthStore.execute(query)
            }
        }

        func averageHeartRate() async -> Int? {
            guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return nil }
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
            return await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                    if let avg = result?.averageQuantity() {
                        let bpm = avg.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                        continuation.resume(returning: Int(bpm))
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
                healthStore.execute(query)
            }
        }

        let activeEnergyBurnedResult = await sumQuantity(.activeEnergyBurned, unit: .kilocalorie(), options: .cumulativeSum)
        let distanceWalkingRunningResult = await sumQuantity(.distanceWalkingRunning, unit: .meter(), options: .cumulativeSum)
        let distanceCyclingResult = await sumQuantity(.distanceCycling, unit: .meter(), options: .cumulativeSum)
        let distanceSwimmingResult = await sumQuantity(.distanceSwimming, unit: .meter(), options: .cumulativeSum)
        let heartRateResult = await averageHeartRate()

        let totalDistanceMeters = (distanceWalkingRunningResult ?? 0) + (distanceCyclingResult ?? 0) + (distanceSwimmingResult ?? 0)

        await MainActor.run {
            if calories.isEmpty, let energy = activeEnergyBurnedResult {
                calories = String(format: "%.0f", energy)
            }
            if distance.isEmpty {
                distance = String(format: "%.2f", totalDistanceMeters / 1000) // meters to km
            }
            if heartRate.isEmpty, let hr = heartRateResult {
                heartRate = String(hr)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                WorkoutPreviewCardView(
                    activityType: selectedActivityType,
                    startDate: startDate,
                    durationMins: max(0, Int(endDate.timeIntervalSince(startDate) / 60)),
                    calories: Double(calories) ?? 0,
                    distanceKm: Double(distance) ?? 0,
                    heartRate: Int(heartRate) ?? 0,
                    pace: {
                        let dur = Double(endDate.timeIntervalSince(startDate) / 60)
                        let dist = Double(distance) ?? 0
                        guard dist > 0, dur > 0 else { return "-" }
                        let paceVal = dur / dist
                        let mins = Int(paceVal)
                        let secs = Int((paceVal - Double(mins)) * 60)
                        return String(format: "%d:%02d", mins, secs)
                    }()
                )
                .padding(.horizontal, 8)
                .padding(.top, 12)

                Button(action: {
                    showingMetrics = true
                }) {
                    Text("Show Detailed Metrics")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(categoryColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
                .sheet(isPresented: $showingMetrics) {
                    MetricsSheet(
                        selectedActivityType: selectedActivityType,
                        calories: calories,
                        distance: distance,
                        heartRate: heartRate,
                        startDate: startDate,
                        endDate: endDate,
                        categoryColor: categoryColor
                    )
                }

                Form {
                    Section(header: HStack(spacing: 6) {
                        Image(systemName: "figure.strengthtraining.functional")
                            .foregroundColor(categoryColor)
                        Text("Workout Type")
                            .fontWeight(.semibold)
                    }) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(workoutTypes, id: \.self) { type in
                                    let selected = selectedActivityType == type
                                    Button(action: { selectedActivityType = type }) {
                                        VStack(spacing: 2) {
                                            Image(systemName: type.icon)
                                                .font(.title2)
                                                .foregroundColor(selected ? .white : .gray)
                                                .padding(8)
                                                .background(selected ? categoryColor : Color(.systemGray5).opacity(0.5))
                                                .clipShape(Circle())
                                            Text(type.displayName)
                                                .font(.caption)
                                                .foregroundColor(selected ? .white : .gray)
                                        }
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 2)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    Section(header: HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .foregroundColor(categoryColor)
                        Text("Workout Details")
                            .fontWeight(.semibold)
                    }) {
                        DatePicker("Start Time", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End Time", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                        TextField("Calories (kcal)", text: $calories)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .calories)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(focusedField == .calories ? categoryColor : Color.clear, lineWidth: 2)
                            )
                        TextField("Distance (km)", text: $distance)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .distance)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(focusedField == .distance ? categoryColor : Color.clear, lineWidth: 2)
                            )
                        TextField("Avg Heart Rate (bpm)", text: $heartRate)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .heartRate)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(focusedField == .heartRate ? categoryColor : Color.clear, lineWidth: 2)
                            )

                        if isAutoFilling {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                        else {
                            Button("Auto Fill from Health App") {
                                Task {
                                    await autoFillFromHealthApp()
                                }
                            }
                            .disabled(startDate >= endDate)
                            .foregroundColor(categoryColor)
                            .padding(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(categoryColor, lineWidth: 1.5)
                            )
                        }
                    }
                }
                .navigationTitle("Add Workout")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                        }
                        Spacer()
                        Button(action: {
                            let durationValue = Int(endDate.timeIntervalSince(startDate) / 60)
                            guard let caloriesValue = Double(calories) else { return }
                            let distanceValue = Double(distance) ?? 0
                            let heartRateValue = Int(heartRate) ?? 0
                            func calculateAveragePace(duration: Int, distance: Double) -> String {
                                guard distance > 0 else { return "-" }
                                let pace = Double(duration) / distance
                                let mins = Int(pace)
                                let secs = Int((pace - Double(mins)) * 60)
                                return String(format: "%d:%02d", mins, secs)
                            }
                            let avgPace = calculateAveragePace(duration: durationValue, distance: distanceValue)

                            let newWorkout = Workout(
                                type: selectedActivityType.displayName,
                                activityType: selectedActivityType,
                                duration: durationValue,
                                averageHeartRate: heartRateValue,
                                averagePace: avgPace,
                                startDate: startDate,
                                endDate: endDate,
                                totalEnergyBurned: caloriesValue,
                                totalDistance: distanceValue * 1000
                            )
                            onSave?(newWorkout)

                            Task {
                                do {
                                    try await HealthKitManager.shared.saveWorkoutToHealthKit(workout: newWorkout, activityType: selectedActivityType)
                                } catch {
                                    print("Failed to save to HealthKit: \(error.localizedDescription)")
                                }
                            }

                            dismiss()
                        }) {
                            Text("Save")
                                .fontWeight(.semibold)
                                .frame(minWidth: 80)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(categoryColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: categoryColor.opacity(0.5), radius: 5, x: 0, y: 2)
                        }
                        .disabled(!isValid)
                    }
                })
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        if focusedField != nil {
                            Button("Done") { focusedField = nil }
                        }
                    }
                }
            }
            .padding(.bottom, 10)
        }
    }
}
private struct MetricsSheet: View {
    let selectedActivityType: HKWorkoutActivityType
    let calories: String
    let distance: String
    let heartRate: String
    let startDate: Date
    let endDate: Date
    let categoryColor: Color

    @Environment(\.dismiss) private var dismiss

    private func formatDuration(from start: Date, to end: Date) -> String {
        let interval = Int(end.timeIntervalSince(start))
        guard interval > 0 else { return "-" }

        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        LinearGradient(
                            colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    )
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: isCompact ? 16 : 28) {
                        HStack {
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(categoryColor)
                                    .padding(isCompact ? 6 : 10)
                                    .background(Color.white.opacity(0.7))
                                    .clipShape(Circle())
                                    .shadow(color: categoryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, isCompact ? 6 : 10)

                        Spacer(minLength: 0)

                        Image(systemName: selectedActivityType.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: isCompact ? 50 : 70, height: isCompact ? 50 : 70)
                            .foregroundColor(categoryColor)
                            .padding(isCompact ? 14 : 22)
                            .background(
                                Circle()
                                    .fill(categoryColor.opacity(0.10))
                                    .shadow(color: categoryColor.opacity(0.15), radius: 8, x: 0, y: 5)
                            )
                            .frame(maxWidth: .infinity)

                        Text(selectedActivityType.displayName)
                            .font(.system(size: isCompact ? 28 : 34, weight: .bold))
                            .foregroundColor(categoryColor)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        HStack(spacing: isCompact ? 12 : 20) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(categoryColor)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Start")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(startDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            }
                            Divider()
                                .frame(height: isCompact ? 30 : 40)
                                .background(Color.secondary.opacity(0.5))
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(categoryColor)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("End")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(endDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, isCompact ? 20 : 32)
                        VStack(spacing: isCompact ? 10 : 16) {
                            metricCard(
                                iconName: "clock",
                                iconColor: categoryColor,
                                valueText: formatDuration(from: startDate, to: endDate),
                                labelText: "Duration",
                                isCompact: isCompact
                            )
                            metricCard(
                                iconName: "flame.fill",
                                iconColor: .red,
                                valueText: calories.isEmpty ? "-" : "\(calories) kcal",
                                labelText: "Calories",
                                isCompact: isCompact
                            )
                            metricCard(
                                iconName: "map.fill",
                                iconColor: .blue,
                                valueText: distance.isEmpty ? "-" : "\(distance) km",
                                labelText: "Distance",
                                isCompact: isCompact
                            )
                            if !heartRate.isEmpty {
                                metricCard(
                                    iconName: "heart.fill",
                                    iconColor: .pink,
                                    valueText: "\(heartRate) bpm",
                                    labelText: "Avg Heart Rate",
                                    isCompact: isCompact
                                )
                            }
                        }
                        .padding(.horizontal, isCompact ? 16 : 24)

                        Spacer(minLength: 0)

                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity, minHeight: isCompact ? 40 : 50)
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(
                                        colors: [categoryColor, categoryColor.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: categoryColor.opacity(0.5), radius: 6, x: 0, y: 3)
                        }
                        .padding(.horizontal, isCompact ? 24 : 32)
                        .padding(.bottom, isCompact ? 14 : 20)
                    }
                    .padding(.vertical, isCompact ? 8 : 10)
                    .padding(.horizontal, 8)
                }
            }
        }
    }

    @ViewBuilder
    private func metricCard(iconName: String, iconColor: Color, valueText: String, labelText: String, isCompact: Bool) -> some View {
        HStack(spacing: isCompact ? 10 : 16) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: isCompact ? 22 : 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(valueText)
                    .font(.system(size: isCompact ? 18 : 22, weight: .bold, design: .rounded))
                    .foregroundColor(categoryColor)
                Text(labelText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, isCompact ? 10 : 16)
        .padding(.horizontal)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .shadow(color: categoryColor.opacity(0.30), radius: 10, x: 0, y: 6)
    }
}

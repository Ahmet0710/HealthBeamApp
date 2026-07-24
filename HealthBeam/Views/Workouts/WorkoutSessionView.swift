import SwiftUI
import HealthKit
import Foundation
import Combine
import MapKit
import CoreMotion
import UIKit
class MotionManager: ObservableObject {
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    @Published var authorized: Bool = false

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        if CMMotionActivityManager.authorizationStatus() == .notDetermined {
            activityManager.queryActivityStarting(from: Date(), to: Date(), to: .main) { _, error in
                DispatchQueue.main.async {
                    let isAuthorized = CMMotionActivityManager.authorizationStatus() == .authorized
                    self.authorized = isAuthorized
                    completion(isAuthorized)
                }
            }
        } else {
            let isAuthorized = CMMotionActivityManager.authorizationStatus() == .authorized
            self.authorized = isAuthorized
            completion(isAuthorized)
        }
    }
}
struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
final class WorkoutLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var route: [IdentifiableCoordinate] = []
    @Published var cameraPosition: MapCameraPosition = .userLocation(fallback: .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )))
    private let manager = CLLocationManager()
    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    func stop() {
        manager.stopUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coord = IdentifiableCoordinate(coordinate: location.coordinate)
        route.append(coord)
        cameraPosition = .camera(MapCamera(centerCoordinate: location.coordinate, distance: 500, heading: 0, pitch: 0))
    }
}
struct WorkoutSessionView: View {
    let activityType: HKWorkoutActivityType
    @Environment(\.dismiss) private var dismiss
    @State private var startTime = Date()
    @State private var isActive = true
    @State private var isPaused = false
    @State private var calories: Double = 0
    @State private var distance: Double = 0
    @State private var pace: Double = 0
    @StateObject private var locManager = WorkoutLocationManager()
    @StateObject private var motionManager = MotionManager()
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var showSummary = false
    @State private var isSaving = false
    @State private var isSharePresented = false
    @State private var isSummarySharePresented = false

    private let totalTarget: TimeInterval = 60 * 60
    private var formattedElapsed: String {
        let intElapsed = Int(elapsed)
        let mins = intElapsed / 60
        let secs = intElapsed % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    private var shareSummaryText: String {
        """
        Workout Summary:
        Activity: \(activityType.displayName)
        Time: \(formattedElapsed)
        Calories: \(Int(calories)) kcal
        Distance: \(String(format: "%.2f km", distance/1000))
        Pace: \(pace.isFinite ? String(format: "%.1f min/km", pace) : "--")
        """
    }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [activityType.color.opacity(0.13), Color(.systemBackground)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                VStack(spacing: geometry.size.height < 700 ? 12 : 20) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                                .shadow(radius: 2, y: 1)
                        }
                        Spacer()
                    }
                    .padding(.top, geometry.size.height < 700 ? 8 : 24)
                    .padding(.horizontal, geometry.size.width < 350 ? 12 : 24) 
                    VStack(spacing: geometry.size.height < 700 ? 6 : 10) {
                        ZStack {
                            Circle()
                                .fill(activityType.color.opacity(0.13))
                                .frame(width: geometry.size.height < 700 ? 48 : 72, height: geometry.size.height < 700 ? 48 : 72)
                                .shadow(color: activityType.color.opacity(0.18), radius: 6, y: 2)
                            Image(systemName: activityType.icon)
                                .font(.system(size: geometry.size.height < 700 ? 24 : 38, weight: .bold))
                                .foregroundColor(activityType.color)
                        }
                        Text(activityType.displayName)
                            .font(.title.bold())
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    .padding(.top, geometry.size.height < 700 ? 8 : 24)
                    ZStack {
                        Map(position: $locManager.cameraPosition, interactionModes: .all) {
                            ForEach(locManager.route) { loc in
                                Annotation("Pin", coordinate: loc.coordinate) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.accentColor.opacity(0.14))
                                            .frame(width: 26, height: 26)
                                        Image(systemName: "mappin")
                                            .font(.title2)
                                            .foregroundColor(Color.accentColor)
                                    }
                                }
                            }
                            if locManager.route.count > 1 {
                                MapPolyline(coordinates: locManager.route.map { $0.coordinate })
                                    .stroke(Color.green, lineWidth: 4)
                            }
                        }
                    }
                    .frame(height: geometry.size.height < 700 ? 88 : 120)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                    .padding(.horizontal, geometry.size.width < 350 ? 12 : 24)
                    .padding(.bottom, geometry.size.height < 700 ? 12 : 20)
                    VStack(spacing: geometry.size.height < 700 ? 10 : 14) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.19))
                                    .frame(width: geometry.size.height < 700 ? 28 : 38, height: geometry.size.height < 700 ? 28 : 38)
                                Image(systemName: "clock.fill")
                                    .font(.system(size: geometry.size.height < 700 ? 14 : 19, weight: .semibold))
                                    .foregroundColor(.accentColor)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Time")
                                    .font(geometry.size.height < 700 ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                                    .foregroundColor(.secondary)
                                Text(formattedElapsed)
                                    .font(geometry.size.height < 700 ? .body.monospacedDigit().weight(.bold) : .title3.monospacedDigit().weight(.bold))
                                    .foregroundColor(.primary)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(geometry.size.height < 700 ? 8 : 10)
                        .background(RoundedRectangle(cornerRadius: geometry.size.height < 700 ? 10 : 14, style: .continuous).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: geometry.size.height < 700 ? 10 : 14, style: .continuous).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.18))
                                    .frame(width: geometry.size.height < 700 ? 28 : 38, height: geometry.size.height < 700 ? 28 : 38)
                                Image(systemName: "flame.fill")
                                    .font(.system(size: geometry.size.height < 700 ? 14 : 19, weight: .semibold)) 
                                    .foregroundColor(.orange)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Calories")
                                    .font(geometry.size.height < 700 ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                                    .foregroundColor(.secondary)
                                Text("\(Int(calories)) kcal")
                                    .font(geometry.size.height < 700 ? .body.monospacedDigit().weight(.bold) : .title3.monospacedDigit().weight(.bold))
                                    .foregroundColor(.primary)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(geometry.size.height < 700 ? 8 : 10)
                        .background(RoundedRectangle(cornerRadius: geometry.size.height < 700 ? 10 : 14, style: .continuous).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: geometry.size.height < 700 ? 10 : 14, style: .continuous).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.18))
                                    .frame(width: geometry.size.height < 700 ? 28 : 38, height: geometry.size.height < 700 ? 28 : 38)
                                Image(systemName: "speedometer")
                                    .font(.system(size: geometry.size.height < 700 ? 14 : 18, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pace")
                                    .font(geometry.size.height < 700 ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                                    .foregroundColor(.secondary)
                                Text(pace.isFinite ? String(format: "%.1f min/km", pace) : "--")
                                    .font(geometry.size.height < 700 ? .body.monospacedDigit().weight(.bold) : .title3.monospacedDigit().weight(.bold))
                                    .foregroundColor(.primary)
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(geometry.size.height < 700 ? 8 : 10)
                        .background(RoundedRectangle(cornerRadius: geometry.size.height < 700 ? 10 : 14, style: .continuous).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: geometry.size.height < 700 ? 10 : 14, style: .continuous).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                    }
                    .padding(.top, geometry.size.height < 700 ? 8 : 12)
                    .padding(.horizontal, geometry.size.width < 350 ? 12 : 24)

                    Spacer()
                }
                .padding(.bottom, geometry.size.height < 700 ? 32 : 95)
                VStack {
                    Spacer()
                    if isPaused {
                        HStack(spacing: 16) {
                            Button(action: resumeWorkout) {
                                Text("Resume")
                                    .font(.title2.bold())
                                    .frame(maxWidth: .infinity, minHeight: geometry.size.height < 700 ? 44 : 60)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(18)
                            }
                            Button(action: endWorkout) {
                                Text("End Workout")
                                    .font(.title2.bold())
                                    .frame(maxWidth: .infinity, minHeight: geometry.size.height < 700 ? 44 : 60)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(18)
                            }
                        }
                        .padding(.horizontal, geometry.size.width < 350 ? 12 : 16)
                        .padding(.bottom, geometry.size.height < 700 ? 20 : 30)
                    } else {
                        HStack(spacing: 16) {
                            Button(action: pauseWorkout) {
                                Text("Pause")
                                    .font(.title2.bold())
                                    .frame(maxWidth: .infinity, minHeight: geometry.size.height < 700 ? 44 : 60)
                                    .background(Color.yellow)
                                    .foregroundColor(.black)
                                    .cornerRadius(18)
                            }
                            Button(action: endWorkout) {
                                Text("End Workout")
                                    .font(.title2.bold())
                                    .frame(maxWidth: .infinity, minHeight: geometry.size.height < 700 ? 44 : 60)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(18)
                            }
                        }
                        .padding(.horizontal, geometry.size.width < 350 ? 12 : 16)
                        .padding(.bottom, geometry.size.height < 700 ? 20 : 30)
                    }
                }

                if isSaving {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Saving Workout...")
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                motionManager.requestAuthorization { granted in
                }
                if isActive {
                    locManager.start()
                }
                startTime = Date()
                calories = 0
                distance = 0
                pace = 0
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    Task { @MainActor in
                        guard !isPaused else { return }
                        elapsed = Date().timeIntervalSince(startTime)
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
                locManager.stop()
            }
            .sheet(isPresented: $showSummary) {
                VStack(spacing: 16) {
                    Spacer(minLength: 0)
                    Text("Workout Summary")
                        .font(.title.bold())
                        .padding(.top, 28)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack { Text("Time:").bold(); Spacer(); Text(formattedElapsed) }
                        HStack { Text("Calories:").bold(); Spacer(); Text("\(Int(calories)) kcal") }
                        HStack { Text("Distance:").bold(); Spacer(); Text(String(format: "%.2f km", distance/1000)) }
                        HStack { Text("Pace:").bold(); Spacer(); Text(pace.isFinite ? String(format: "%.1f min/km", pace) : "--") }
                    }
                    .font(.body)
                    .padding(.horizontal)
                    Map(initialPosition: .camera(MapCamera(centerCoordinate: (locManager.route.last?.coordinate ?? CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020)), distance: 500, heading: 0, pitch: 0))) {
                        ForEach(locManager.route) { loc in
                            Annotation("Pin", coordinate: loc.coordinate) {
                                Circle().fill(Color.accentColor.opacity(0.18)).frame(width: 16, height: 16)
                            }
                        }
                        if locManager.route.count > 1 {
                            MapPolyline(coordinates: locManager.route.map { $0.coordinate })
                                .stroke(Color.green, lineWidth: 4)
                        }
                    }
                    .frame(height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal)
                    HStack(spacing: 16) {
                        Button(action: {
                            dismiss()}){
                                Text("Done")
                                    .font(.title2.bold())
                                    .frame(maxWidth: .infinity, minHeight: 56)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                            }
                            .task {
                                await saveWorkout()
                            }
                        Button(action: {
                            isSummarySharePresented = true
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(Color(.systemGray5))
                                .foregroundColor(.accentColor)
                                .cornerRadius(14)
                        }
                    }
                    .padding([.horizontal, .bottom])
                }
                .background(.ultraThinMaterial)
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isSummarySharePresented) {
                ShareSheet(activityItems: [shareSummaryText])
            }
        }
    }
    @MainActor
    private func saveWorkout() async {
        isSaving = true
        let healthStore = HKHealthStore()
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = .outdoor
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        do {
            try await builder.beginCollection(at: startTime)
            try await builder.endCollection(at: Date())
            _ = try await withCheckedThrowingContinuation { continuation in
                builder.finishWorkout { workout, error in
                    if let workout = workout {
                        continuation.resume(returning: workout)
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: NSError(domain: "WorkoutErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error finishing workout"]))
                    }
                }
            }
            await MainActor.run {
                isSaving = false
            }
        } catch {
            await MainActor.run {
                isSaving = false
            }
        }
    }
    private func endWorkout() {
        isActive = false
        timer?.invalidate()
        locManager.stop()
        showSummary = true
    }
    private func pauseWorkout() {
        isPaused = true
    }
    private func resumeWorkout() {
        isPaused = false
        if isActive {
            locManager.start()
        }
    }
}


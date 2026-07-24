import SwiftUI
import HealthKit
struct StartWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedActivity: HKWorkoutActivityType = .running
    @State private var showSheet = false
    @State private var navigateToSession = false
    @State private var searchText = ""
    let activityTypes: [HKWorkoutActivityType] = [
        .running, .walking, .cycling, .swimming, .hiking, .yoga, .functionalStrengthTraining, .traditionalStrengthTraining, .highIntensityIntervalTraining, .mixedCardio, .rowing, .elliptical, .jumpRope, .pilates, .boxing, .other
    ]
    var filteredActivities: [HKWorkoutActivityType] {
        if searchText.isEmpty { return activityTypes }
        return activityTypes.filter { $0.displayName.lowercased().contains(searchText.lowercased()) }
    }
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(colors: [selectedActivity.color.opacity(0.5), .black],
                               startPoint: .top,
                               endPoint: .bottom)
                .ignoresSafeArea()
                VStack(spacing: 36) {
                    Text("\"Every great journey starts with one step.\"")
                        .font(.title3.italic())
                        .foregroundColor(.secondary)
                        .padding(.top, 38)
                        .padding(.horizontal)

                    Button(action: { showSheet = true }) {
                        VStack(spacing: 20) {
                            Circle()
                                .fill(selectedActivity.color.opacity(0.2))
                                .frame(width: 88, height: 88)
                                .overlay(
                                    Image(systemName: selectedActivity.icon)
                                        .font(.system(size: 44, weight: .bold))
                                        .foregroundColor(selectedActivity.color)
                                )
                            Text(selectedActivity.displayName)
                                .font(.largeTitle.bold())
                                .foregroundColor(selectedActivity.color)
                            Text("Tap to change activity")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(30)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .fill(Color.clear)
                                .shadow(color: .clear, radius: 0)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)

                    Spacer()
                }
                Button(action: { navigateToSession = true }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .padding(22)
                        .background(selectedActivity.color)
                        .clipShape(Circle())
                        .shadow(color: selectedActivity.color.opacity(0.21), radius: 12, y: 3)
                        .padding([.bottom, .trailing], 26)
                        .accessibilityLabel("Start Workout")
                }
                .buttonStyle(.plain)
            }
            .navigationDestination(isPresented: $navigateToSession) {
                WorkoutSessionView(activityType: selectedActivity)
            }
            .sheet(isPresented: $showSheet) {
                NavigationStack {
                    VStack(spacing: 0) {
                        TextField("Search activities", text: $searchText)
                            .padding(.horizontal , 10)
                            .padding(.vertical , 10)
                            .glassEffect(.regular.interactive())
                        List(filteredActivities, id: \.self) { type in
                            Button(action: {
                                selectedActivity = type
                                showSheet = false
                                searchText = ""        
                            }) {
                                HStack {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(type.color)
                                    Text(type.displayName)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                        .listStyle(.insetGrouped)
                    }
                    .navigationTitle("Select Activity")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Cancel") { showSheet = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .navigationTitle("Start Workout")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

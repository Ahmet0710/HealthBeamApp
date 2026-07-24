import SwiftUI

struct HabitsView: View {
    @StateObject private var viewModel = HabitsViewModel()
    @EnvironmentObject private var achievementsViewModel: AchievementsViewModel
    @State private var showingAddHabit = false
    @State private var selectedCategory: String = "All"
    let categories = ["All", "Morning", "Afternoon", "Evening"]

    private func localizedCategory(_ category: String) -> String {
        switch category {
        case "All": return String(localized: "All")
        case "Morning": return String(localized: "Morning")
        case "Afternoon": return String(localized: "Afternoon")
        case "Evening": return String(localized: "Evening")
        default: return category
        }
    }

    private func progressBarColor(for progress: Double) -> Color {
        switch progress {
        case 0..<0.20: return .red.opacity(0.8)
        case 0.20..<0.40: return .red
        case 0.40..<0.60: return .yellow.opacity(0.8)
        case 0.60..<0.80: return .yellow
        case 0.80..<1.0: return .green.opacity(0.5)
        case 1.0: return .green
        default: return .gray
        }
    }

    var body: some View {
        let completedDays = viewModel.weeklyProgress.completedDays
        let totalDays = viewModel.weeklyProgress.totalDays
        let progressValue = totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0.0

        let filteredHabits = viewModel.habits.filter { habit in
            selectedCategory == "All" || habit.category == selectedCategory
        }

        NavigationStack {
            ZStack {
                backgroundView

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        categoryPicker

                        weeklyProgressSummary(completedDays: completedDays, totalDays: totalDays, progressValue: progressValue)

                        habitList(filteredHabits: filteredHabits)
                    }
                    .padding(.bottom, 10)
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    viewModel.setup(achievementsViewModel: achievementsViewModel)
                    viewModel.refreshBadges()
                    achievementsViewModel.syncHabitAchievements(from: viewModel.habits)
                }
                .onChange(of: viewModel.habits) { _, _ in
                    viewModel.saveHabits()
                    viewModel.refreshBadges()
                }

                if viewModel.showConfetti {
                    ConfettiView()
                        .transition(.opacity)
                        .animation(.easeInOut, value: viewModel.showConfetti)
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing){
                    Button {
                        showingAddHabit = true
                    } label: {
                        Text("Add Habits")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitSheet { name, icon, color, time, category in
                    let newHabit = Habit(name: name, icon: icon, color: color, isCompleted: false, streak: 0, time: time, completionDates: [], category: category)
                    viewModel.addHabit(newHabit)
                }
            }
        }
    }
    
    private var backgroundView: some View {
        Group {
                LinearGradient(colors: [.blue.opacity(0.5), .black],
                startPoint: .top,
                endPoint: .bottom)
                .ignoresSafeArea()
        }
    }

    private var categoryPicker: some View {
        Picker("Category", selection: $selectedCategory) {
            ForEach(categories, id: \.self) { category in
                Text(localizedCategory(category))
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private func weeklyProgressSummary(completedDays: Int, totalDays: Int, progressValue: Double) -> some View {
        Group {
            if totalDays > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Progress")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    ProgressView(value: progressValue)
                        .tint(progressBarColor(for: progressValue))
                        .scaleEffect(x: 1, y: 3, anchor: .center)
                        .animation(.easeInOut, value: progressValue)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(5)
                    Text(String(localized: "\(completedDays) of \(totalDays) habits completed"))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
            }
        }
    }

    private func habitList(filteredHabits: [Habit]) -> some View {
        ForEach(filteredHabits, id: \.id) { habit in
            if let habitIndex = viewModel.habits.firstIndex(where: { $0.id == habit.id }) {
                NavigationLink(destination: HabitDetailView(
                    habit: viewModel.habits[habitIndex],
                    onUpdate: { updatedHabit in
                        viewModel.updateHabit(updatedHabit)
                    },
                    onDelete: { habit in
                        viewModel.removeHabit(habit)
                    }
                )) {
                    HabitCard(
                        habit: viewModel.habits[habitIndex],
                        onToggle: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            viewModel.toggleHabitCompletion(for: viewModel.habits[habitIndex].id)
                        }
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}

struct HabitCard: View {
    var habit: Habit
    var onToggle: () -> Void

    @State private var isPressed = false

    private var formattedTime: String {
        let calendar = Calendar.current
        if let date = calendar.date(from: habit.time) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        return ""
    }

    private var last7Days: [Date] {
        let todayMidnight = Calendar.current.startOfDay(for: .now)
        return (0..<7).map { Calendar.current.date(byAdding: .day, value: -$0, to: todayMidnight)! }.reversed()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)

                    let progress = Double(habit.completionDates.filter { date in
                        last7Days.contains { Calendar.current.isDate($0, inSameDayAs: date) }
                    }.count) / 7.0

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(habit.colorValue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 50, height: 50)
                        .animation(.easeInOut(duration: 0.5), value: progress)

                    Circle()
                        .fill(habit.colorValue.opacity(habit.isCompleted ? 0.7 : 0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: habit.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(habit.isCompleted ? .white : habit.colorValue)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(habit.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    if !formattedTime.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(formattedTime)
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(String(localized: "Streak: \(habit.streak)"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        isPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isPressed = false
                        onToggle()
                    }
                }) {
                    Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(habit.isCompleted ? habit.colorValue : .secondary)
                        .scaleEffect(isPressed ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isPressed)
                }
                .buttonStyle(PlainButtonStyle())
            }
            HStack(spacing: 6) {
                ForEach(last7Days, id: \.self) { date in
                    Circle()
                        .frame(width: 10, height: 10)
                        .foregroundColor(habit.completionDates.contains(date) ? habit.colorValue : .gray.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.13)))
        .shadow(color: Color.primary.opacity(0.06), radius: 6, x: 0, y: 2)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onToggle()
            } label: {
                Label("Complete", systemImage: "checkmark.circle")
            }
            .tint(.green)
        }
    }
}

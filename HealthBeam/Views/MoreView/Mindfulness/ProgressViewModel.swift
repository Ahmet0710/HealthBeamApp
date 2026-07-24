import Foundation
import Combine

class ProgressViewModel: ObservableObject {

    @Published var totalMinutes: Int = 0
    @Published var totalSessions: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var weeklyData: [DailyMinutes] = []
    @Published var todayMinutes: Int = 0
    @Published var goalProgress: Double = 0.0
    @Published var weeklyGoalProgress: Int = 0
    @Published var monthlyGoalProgress: Int = 0
    @Published var dailyGoalInMinutes: Int = 20
    @Published var monthlyGoalTarget: Int = 20
    @Published var weeklyGoalTarget: Int = 7

    private let historyManager: HistoryManager
    private let settingsManager: SettingsManager

    init(historyManager: HistoryManager = .shared, settingsManager: SettingsManager = .shared) {
        self.historyManager = historyManager
        self.settingsManager = settingsManager

        loadGoals()
        self.weeklyGoalTarget = settingsManager.loadWeeklyGoal()
        calculateAllStats()
    }

    func loadGoals() {
        self.dailyGoalInMinutes = settingsManager.loadDailyGoal()
        self.monthlyGoalTarget = settingsManager.loadMonthlyGoal()
        self.weeklyGoalTarget = settingsManager.loadWeeklyGoal()
    }

    func updateDailyGoal(newGoal: Int) {
        settingsManager.saveDailyGoal(minutes: newGoal)
        loadGoals()
        calculateAllStats()
    }

    func updateMonthlyGoal(newGoal: Int) {
        settingsManager.saveMonthlyGoal(days: newGoal)
        loadGoals()
    }

    func updateWeeklyGoal(newGoal: Int) {
        settingsManager.saveWeeklyGoal(days: newGoal)
        loadGoals()
        calculateAllStats()
    }

    func calculateAllStats() {
        let allSessions = self.historyManager.loadSessions()
        let meditationDurations = allMeditations.reduce(into: [UUID: Int]()) { $0[$1.id] = $1.durationInMinutes }
        let uniqueDays = Set(allSessions.map { Calendar.current.startOfDay(for: $0.completionDate) })

        self.totalSessions = allSessions.count
        self.totalMinutes = allSessions.reduce(0) { $0 + (meditationDurations[$1.meditationID] ?? 0) }

        let streaks = calculateStreaks(from: uniqueDays)
        self.currentStreak = streaks.current
        self.longestStreak = streaks.longest

        let goalProgress = calculateGoalProgress(from: uniqueDays)
        self.weeklyGoalProgress = goalProgress.weekly
        self.monthlyGoalProgress = goalProgress.monthly

        self.weeklyData = calculateWeeklyData(from: allSessions, using: meditationDurations)
        calculateTodayProgress(from: allSessions, using: meditationDurations, goal: self.dailyGoalInMinutes)
    }


    private func calculateTodayProgress(from sessions: [CompletedSession], using durations: [UUID: Int], goal: Int) {
        let todaySessions = sessions.filter { Calendar.current.isDateInToday($0.completionDate) }
        self.todayMinutes = todaySessions.reduce(0) { total, session in total + (durations[session.meditationID] ?? 0) }
        guard goal > 0 else { self.goalProgress = 0; return }
        self.goalProgress = min(1.0, Double(self.todayMinutes) / Double(goal))
    }

    private func calculateWeeklyData(from sessions: [CompletedSession], using durations: [UUID: Int]) -> [DailyMinutes] {
        var dailyData: [Date: Int] = [:]
        let calendar = Calendar.current
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) { dailyData[calendar.startOfDay(for: date)] = 0 }
        }
        sessions.forEach { session in
            let sessionDay = calendar.startOfDay(for: session.completionDate)
            if dailyData[sessionDay] != nil { dailyData[sessionDay, default: 0] += (durations[session.meditationID] ?? 0) }
        }
        return dailyData.map { DailyMinutes(date: $0.key, minutes: $0.value) }.sorted(by: { $0.date < $1.date })
    }

    private func calculateGoalProgress(from uniqueDays: Set<Date>) -> (weekly: Int, monthly: Int) {
        let calendar = Calendar.current, today = Date()
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today)!
        let weeklyProgress = uniqueDays.filter { weekInterval.contains($0) }.count
        let monthInterval = calendar.dateInterval(of: .month, for: today)!
        let monthlyProgress = uniqueDays.filter { monthInterval.contains($0) }.count
        return (weeklyProgress, monthlyProgress)
    }

    private func calculateStreaks(from uniqueDays: Set<Date>) -> (current: Int, longest: Int) {
        guard !uniqueDays.isEmpty else { return (0, 0) }
        let sortedDays = uniqueDays.sorted(by: >)
        var longestStreak = 1, currentStreak = 0, runningStreak = 1
        for i in 1..<sortedDays.count {
            if Calendar.current.date(byAdding: .day, value: -1, to: sortedDays[i-1])! == sortedDays[i] { runningStreak += 1 } else { runningStreak = 1 }
            if runningStreak > longestStreak { longestStreak = runningStreak }
        }
        let today = Calendar.current.startOfDay(for: Date()), yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        if let mostRecentDay = sortedDays.first, mostRecentDay == today || mostRecentDay == yesterday {
            currentStreak = 1
            for i in 1..<sortedDays.count {
                if Calendar.current.date(byAdding: .day, value: -1, to: sortedDays[i-1])! == sortedDays[i] { currentStreak += 1 } else { break }
            }
        }
        return (currentStreak, longestStreak)
    }
}

struct DailyMinutes: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
}


import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    private let dailyGoalKey = "dailyGoalInMinutes"
    private let weeklyGoalKey = "weeklyGoalTarget"
    private let monthlyGoalKey = "monthlyGoalTarget"
    private init() {}
    func loadDailyGoal() -> Int {
        UserDefaults.standard.integer(forKey: dailyGoalKey) == 0 ? 20 : UserDefaults.standard.integer(forKey: dailyGoalKey)
    }
    func loadWeeklyGoal() -> Int {
        UserDefaults.standard.integer(forKey: weeklyGoalKey) == 0 ? 7 : UserDefaults.standard.integer(forKey: weeklyGoalKey)
    }
    func loadMonthlyGoal() -> Int {
        UserDefaults.standard.integer(forKey: monthlyGoalKey) == 0 ? 20 : UserDefaults.standard.integer(forKey: monthlyGoalKey)
    }
    func saveDailyGoal(minutes: Int) {
        UserDefaults.standard.set(minutes, forKey: dailyGoalKey)
    }
    func saveWeeklyGoal(days: Int) {
        UserDefaults.standard.set(days, forKey: weeklyGoalKey)
    }
    func saveMonthlyGoal(days: Int) {
        UserDefaults.standard.set(days, forKey: monthlyGoalKey)
    }
}

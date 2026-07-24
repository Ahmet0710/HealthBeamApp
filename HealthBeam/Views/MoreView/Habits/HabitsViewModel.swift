import SwiftUI
import Combine
import UserNotifications

class HabitsViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var badges: [Badge] = allBadges
    @Published var showConfetti: Bool = false
    
    var achievementsViewModel: AchievementsViewModel?
    private let notificationService = NotificationService()
    
    // Demo modunu dinlemek için Cancellables seti ekledik
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadHabits()
        
        // Demo modu kapalıysa (gerçek kullanım) gün kontrolü yap
        if !AppReviewManager.shared.isDemoMode {
            resetCompletionIfNewDay()
        }
        
        refreshBadges()
        
        // MARK: - DEMO MODU DİNLEYİCİSİ
        AppReviewManager.shared.$isDemoMode
            .receive(on: RunLoop.main)
            .sink { [weak self] isDemo in
                if isDemo {
                    print("🔄 Habits Demo Modu: Alışkanlıklar yükleniyor...")
                    self?.loadHabits()
                }
            }
            .store(in: &cancellables)
    }
    
    func setup(achievementsViewModel: AchievementsViewModel) {
        self.achievementsViewModel = achievementsViewModel
    }

    func loadHabits() {
        // MARK: - Demo Modu Kontrolü
        if AppReviewManager.shared.isDemoMode {
            // Mock verileri yükle
            self.habits = MockHabits.sampleHabits
            return
        }
        
        // Normal Yükleme
        if let data = UserDefaults.standard.data(forKey: "habits"),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        } else {
            habits = []
        }
    }

    func saveHabits() {
        // Demo modunda kaydetmeyi engelle
        if AppReviewManager.shared.isDemoMode { return }
        
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: "habits")
        }
    }

    private func midnight(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    func resetCompletionIfNewDay() {
        // Demo modunda sıfırlama yapma
        if AppReviewManager.shared.isDemoMode { return }
        
        let today = midnight(for: .now)
        for i in habits.indices {
            if habits[i].isCompleted && !habits[i].completionDates.contains(today) {
                habits[i].isCompleted = false
            }
        }
    }

    func toggleHabitCompletion(for habitID: UUID) {
        guard let index = habits.firstIndex(where: { $0.id == habitID }) else { return }
        
        // Demo modunda sadece UI üzerinde değişiklik yap (streak hesaplama vs. simüle et)
        // Kaydetme işlemi zaten saveHabits() içinde engellendiği için sorun olmaz.

        let today = midnight(for: .now)
        if !habits[index].completionDates.contains(today) {
            habits[index].isCompleted = true
            habits[index].completionDates.insert(today)
            habits[index].streak += 1
        } else {
            habits[index].isCompleted = false
            habits[index].completionDates.remove(today)
            if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today),
               !habits[index].completionDates.contains(yesterday) {
                habits[index].streak = 0 // Streak kırılır
            } else {
                habits[index].streak = max(0, habits[index].streak - 1)
            }
        }
        
        saveHabits() // Demo modundaysa içi boş döner
        refreshBadges()
        achievementsViewModel?.syncHabitAchievements(from: habits)

        let progress = weeklyProgress
        if progress.completedDays == progress.totalDays && progress.totalDays > 0 {
            self.showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showConfetti = false
            }
        }
    }

    func refreshBadges() {
        // Demo modunda rozetleri de otomatik açık varsayabiliriz ama
        // MockHabits zaten yüksek streak'li olduğu için mantık çalışarak açacaktır.
        for index in badges.indices {
            switch badges[index].milestone {
            case 5, 10:
                badges[index].unlocked = habits.contains(where: { $0.streak >= badges[index].milestone })
            case 7:
                let todayMidnight = Calendar.current.startOfDay(for: .now)
                let last7Days = (0..<7).map { Calendar.current.date(byAdding: .day, value: -$0, to: todayMidnight)! }

                badges[index].unlocked = habits.allSatisfy { habit in
                    last7Days.allSatisfy { day in
                        habit.completionDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: day) })
                    }
                }
            default:
                break
            }
        }
    }

    func updateHabit(_ habit: Habit) {
        // Demo modunda düzenlemeyi engelle veya sadece bellekte yap
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            saveHabits()
            refreshBadges()
            achievementsViewModel?.syncHabitAchievements(from: habits)
            
            if !AppReviewManager.shared.isDemoMode {
                notificationService.scheduleNotification(for: habit)
            }
        }
    }

    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
        refreshBadges()
        achievementsViewModel?.syncHabitAchievements(from: habits)
        
        if !AppReviewManager.shared.isDemoMode {
            notificationService.scheduleNotification(for: habit)
        }
    }

    func removeHabit(_ habit: Habit) {
        if !AppReviewManager.shared.isDemoMode {
            notificationService.cancelNotification(for: habit.id)
        }
        
        habits.removeAll { $0.id == habit.id }
        saveHabits()
        refreshBadges()
        achievementsViewModel?.syncHabitAchievements(from: habits)
    }

    var weeklyProgress: (completedDays: Int, totalDays: Int) {
        let todayMidnight = Calendar.current.startOfDay(for: .now)
        let last7 = (0..<7).map { Calendar.current.date(byAdding: .day, value: -$0, to: todayMidnight)! }
        let totalDays = 7 * habits.count
        let completedDays = habits.reduce(0) { total, habit in
            total + habit.completionDates.filter { date in
                last7.contains { Calendar.current.isDate($0, inSameDayAs: date) }
            }.count
        }
        return (completedDays, totalDays)
    }
}

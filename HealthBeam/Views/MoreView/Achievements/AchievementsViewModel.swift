import SwiftUI
import Combine
import HealthKit

enum AchievementFilter: String, CaseIterable, Identifiable {
    case all = "All"; case unlocked = "Unlocked"; case locked = "Locked"
    var id: String { self.rawValue }

    var localizedTitle: String {
        switch self {
        case .all: return String(localized: "All")
        case .unlocked: return String(localized: "Unlocked")
        case .locked: return String(localized: "Locked")
        }
    }
}
enum AchievementSort: String, CaseIterable, Identifiable {
    case Default = "Default"; case Progress = "Progress"; case Title = "Title"
    var id: String { self.rawValue }

    var localizedTitle: String {
        switch self {
        case .Default: return String(localized: "Default")
        case .Progress: return String(localized: "Progress")
        case .Title: return String(localized: "Title")
        }
    }
}

class AchievementsViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var activeFilter: AchievementFilter = .all
    @Published var activeSort: AchievementSort = .Default
    @Published var searchText = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let healthKitManager = HealthKitManager.shared
    
    private var savePath: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("achievements.json")
    }

    private static let achievementAliasesByID: [String: [String]] = [
        "workouts.warm_up": ["Warm-up Lap"],
        "workouts.one_hour_resistance": ["One Hour Endurance"],
        "workouts.strength_starter": ["Strength Start"],
        "workouts.explorer": ["Traveler"],
        "nutrition.protein_power": ["Protein Boost"],
        "nutrition.food_diary": ["Meal Diary"],
        "nutrition.no_junk_food": ["Say No to Junk Food"],
        "sleep.goal_streak": ["Sleep Target Streak"],
        "journaling.first_page": ["Ilk Sayfa", "İlk Sayfa"],
        "journaling.daily_streak": ["Gunluk Serisi", "Günlük Serisi"],
        "journaling.gratitude": ["Minnettarlik", "Minnettarlık"],
        "journaling.deep_thought": ["Derin Dusunce", "Derin Düşünce"],
        "journaling.mood_tracker": ["Duygu Takibi"],
        "journaling.capture_moment": ["Ani Yakala", "Anı Yakala"],
        "journaling.set_goals": ["Hedef Belirle"],
        "journaling.brainstorm": ["Beyin Firtinasi", "Beyin Fırtınası"],
        "journaling.monthly_writer": ["Aylik Yazar", "Aylık Yazar"],
        "journaling.look_back": ["Gecmise Bakis", "Geçmişe Bakış"]
    ]

    private static let heuristicAchievementIDs: Set<String> = [
        "nutrition.healthy_meal",
        "nutrition.rainbow_plate",
        "sleep.consistent_pattern",
        "sleep.silent_environment",
        "sleep.power_nap",
        "habits.goal_oriented",
        "breathing.calm_down",
        "breathing.focus_session",
        "breathing.before_sleep",
        "breathing.box_breathing",
        "breathing.heartbeat"
    ]
    
    var displayAchievements: [Achievement] {
        var processedAchievements = achievements
        switch activeFilter {
        case .all: break
        case .unlocked: processedAchievements = achievements.filter { !$0.isLocked }
        case .locked: processedAchievements = achievements.filter { $0.isLocked }
        }
        if !searchText.isEmpty {
            processedAchievements = processedAchievements.filter {
                $0.localizedTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch activeSort {
        case .Default: break
        case .Progress: processedAchievements.sort { $0.progress > $1.progress }
        case .Title: processedAchievements.sort { $0.localizedTitle < $1.localizedTitle }
        }
        return processedAchievements
    }
    
    var unlockedCount: Int { achievements.filter { !$0.isLocked }.count }
    var totalCount: Int { achievements.count }
    var overallProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
    
    init() {
        loadAchievements()
        setupAutoSave()
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshAchievements()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .meditationSessionCompleted)
            .sink { [weak self] _ in
                Task {
                    await self?.syncMindfulnessAchievements()
                }
            }
            .store(in: &cancellables)
        
        // MARK: - DEMO MODU DİNLEYİCİSİ
        // Demo modu değiştiğinde başarıları yeniden yükle
        AppReviewManager.shared.$isDemoMode
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadAchievements()
                if AppReviewManager.shared.isDemoMode {
                    print("🔄 Demo Modu: Başarılar açılıyor...")
                } else {
                    Task { [weak self] in
                        await self?.refreshAchievements()
                    }
                }
            }
            .store(in: &cancellables)

        Task { [weak self] in
            await self?.refreshAchievements()
        }
    }

    func setupAutoSave() {
        $achievements
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.saveAchievements() }
            .store(in: &cancellables)
    }

    func saveAchievements() {
        // Demo modunda kaydetmeyi engelle
        if AppReviewManager.shared.isDemoMode { return }
        
        let progressData = achievements.map { AchievementProgress(id: $0.id, isLocked: $0.isLocked, progress: $0.progress) }
        do {
            let data = try JSONEncoder().encode(progressData)
            // HATA DÜZELTME: Sadece .atomic kullanıyoruz, completeFileProtection bazen sorun çıkarabilir.
            try data.write(to: savePath, options: [.atomic])
        } catch { print("Achievement progress did not save: \(error)") }
    }

    func userCompletedAction(achievementTitle: String) {
        if AppReviewManager.shared.isDemoMode { return }
        
        if let index = achievementIndex(matching: achievementTitle) {
            guard achievements[index].isLocked else { return }
            debugLog("manual completion matched '\(achievementTitle)' -> \(achievements[index].id)")
            withAnimation {
                achievements[index].progress = 1.0
                achievements[index].isLocked = false
            }
            saveAchievements()
        } else {
            debugLog("manual completion '\(achievementTitle)' did not match any achievement")
        }
    }

    func loadAchievements() {
        // MARK: - Demo Modu Kontrolü
        if AppReviewManager.shared.isDemoMode {
            self.achievements = MockAchievements.allUnlocked
            return
        }
        
        var masterList = Achievement.mockData
        do {
            let data = try Data(contentsOf: savePath)
            let savedProgress = try JSONDecoder().decode([AchievementProgress].self, from: data)
            let progressMap = Dictionary(uniqueKeysWithValues: savedProgress.map { ($0.id, $0) })
            for i in 0..<masterList.count {
                let achievementID = masterList[i].id
                if let progress = progressMap[achievementID] {
                    masterList[i].isLocked = progress.isLocked
                    masterList[i].progress = progress.progress
                }
            }
        } catch { print("No progress found, default mock data will be used") }
        self.achievements = masterList
    }

    func progressFor(category: AchievementCategory) -> (unlocked: Int, total: Int, progress: Double) {
        let categoryAchievements = achievements.filter { $0.category == category }
        let unlockedInCategory = categoryAchievements.filter { !$0.isLocked }.count
        let totalInCategory = categoryAchievements.count
        let progress = totalInCategory > 0 ? Double(unlockedInCategory) / Double(totalInCategory) : 0
        return (unlockedInCategory, totalInCategory, progress)
    }

    func requestHealthKitAuthorization() async {
        if AppReviewManager.shared.isDemoMode { return }
        
        do {
            try await healthKitManager.requestAuthorization()
            await refreshAchievements()
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }

    func refreshAchievements() async {
        if AppReviewManager.shared.isDemoMode { return }

        debugLog("refresh start")
        await checkHealthKitAchievements()
        syncHabitAchievements()
        await syncMindfulnessAchievements()
        debugLog("refresh end")
        debugPrintCoverageSummary()
    }

    func markAchievementCompleted(id: String) {
        if AppReviewManager.shared.isDemoMode { return }

        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return }
        guard achievements[index].isLocked else { return }

        debugLog("unlock \(id) via direct completion")
        withAnimation {
            achievements[index].progress = 1.0
            achievements[index].isLocked = false
        }
        saveAchievements()
    }

    func updateAchievementProgress(id: String, currentProgress: Double) {
        if AppReviewManager.shared.isDemoMode { return }

        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return }

        var didChange = false
        let newProgress = min(max(currentProgress / achievements[index].goal, 0), 1.0)
        if achievements[index].isLocked {
            if achievements[index].progress != newProgress {
                debugLog("progress \(id): raw=\(formatDebug(currentProgress)) normalized=\(formatDebug(newProgress))")
                achievements[index].progress = newProgress
                didChange = true
            }
            if achievements[index].progress >= 1.0 {
                debugLog("unlock \(id) via progress")
                achievements[index].isLocked = false
                achievements[index].progress = 1.0
                didChange = true
            }
        }
        if didChange {
            saveAchievements()
        }
    }

    @MainActor
    func checkHealthKitAchievements() async {
        if AppReviewManager.shared.isDemoMode { return }
        
        print("Checking HealthKit Achievements...")
        let totalWorkouts = await healthKitManager.fetchTotalWorkoutCount()
        updateAchievementProgress(title: "Workout Guru", currentProgress: Double(totalWorkouts))
        if totalWorkouts > 0 {
            updateAchievementProgress(title: "First Steps", currentProgress: 1.0)
        }
        
        let totalCaloriesAllTime = await healthKitManager.fetchTotalEnergyBurnedAllTime()
        updateAchievementProgress(title: "Warm-up Lap", currentProgress: totalCaloriesAllTime)
        
        let maxDistance = await healthKitManager.fetchMaxDistanceInWorkout()
        updateAchievementProgress(title: "5K Runner", currentProgress: maxDistance)
        
        let longestDuration = await healthKitManager.fetchLongestWorkoutDuration()
        updateAchievementProgress(title: "One Hour Endurance", currentProgress: longestDuration)
        
        let maxCaloriesInOneWorkout = await healthKitManager.fetchHighestEnergyBurnedInWorkout()
        updateAchievementProgress(title: "Calorie Monster", currentProgress: maxCaloriesInOneWorkout)
        
        let currentStreak = await healthKitManager.fetchCurrentWorkoutStreak()
        updateAchievementProgress(title: "Weekly Streak", currentProgress: Double(currentStreak))
        
        if await healthKitManager.checkAnyWorkoutAfter(hour: 22) { updateAchievementProgress(title: "Night Owl", currentProgress: 1.0) }
        if await healthKitManager.checkIfWorkoutTypeExists(activityType: .traditionalStrengthTraining) { updateAchievementProgress(title: "Strength Start", currentProgress: 1.0) }
        
        let maxDailySteps = await healthKitManager.fetchMaxDailyStepCount()
        updateAchievementProgress(title: "Traveler", currentProgress: maxDailySteps)

        let lastNightSleep = await healthKitManager.fetchLastNightSleepDuration()
        updateAchievementProgress(title: "Good Night Sleep", currentProgress: lastNightSleep)

        let todaysWater = await healthKitManager.fetchTodaysWaterIntake()
        updateAchievementProgress(title: "Water Champion", currentProgress: todaysWater * 4)

        let allSleepData = await healthKitManager.fetchAllSleepData()
        guard !allSleepData.isEmpty else { return }

        if let lastNight = allSleepData.first {
            let lastNightDurationInHours = lastNight.totalAsleepTime / 3600.0
            updateAchievementProgress(title: "Good Night Sleep", currentProgress: lastNightDurationInHours)

            let deepSleepInMinutes = lastNight.duration(of: .deep) / 60.0
            updateAchievementProgress(title: "Deep Sleeper", currentProgress: deepSleepInMinutes)

            if let sleepStartTime = lastNight.dateInterval?.start {
                let hour = Calendar.current.component(.hour, from: sleepStartTime)
                if hour < 23 { updateAchievementProgress(title: "Golden Hours", currentProgress: 1.0) }
            }

            if let sleepEndTime = lastNight.dateInterval?.end {
                let hour = Calendar.current.component(.hour, from: sleepEndTime)
                if hour < 7 { updateAchievementProgress(title: "Early Riser", currentProgress: 1.0) }
            }
            if lastNight.sleepScore >= 85 { updateAchievementProgress(title: "Quality Sleep", currentProgress: 1.0) }
            let awakeningCount = lastNight.stagePeriods.filter { $0.type == .awake }.count
            if awakeningCount <= 1 { updateAchievementProgress(title: "Uninterrupted Night", currentProgress: 1.0) }
        }
        let sleepStreak = await healthKitManager.fetchSleepStreak(sleepGoalInHours: 7.0)
        updateAchievementProgress(title: "Sleep Target Streak", currentProgress: Double(sleepStreak))

        let consistentPatternStreak = sleepConsistencyStreak(from: allSleepData)
        updateAchievementProgress(id: "sleep.consistent_pattern", currentProgress: Double(consistentPatternStreak))

        if allSleepData.contains(where: hasSilentSleep) {
            markAchievementCompleted(id: "sleep.silent_environment")
        }

        if allSleepData.contains(where: isPowerNap) {
            markAchievementCompleted(id: "sleep.power_nap")
        }
    }

    @MainActor
    private func updateAchievementProgress(title: String, currentProgress: Double) {
        if let index = achievementIndex(matching: title) {
            var didChange = false
            let newProgress = min(max(currentProgress / achievements[index].goal, 0), 1.0)
            if achievements[index].isLocked {
                if achievements[index].progress != newProgress {
                    debugLog("progress \(achievements[index].id) from title '\(title)': raw=\(formatDebug(currentProgress)) normalized=\(formatDebug(newProgress))")
                    achievements[index].progress = newProgress
                    didChange = true
                }
                if achievements[index].progress >= 1.0 {
                    achievements[index].isLocked = false
                    achievements[index].progress = 1.0
                    debugLog("unlock \(achievements[index].id) from title '\(title)'")
                    didChange = true
                }
            }
            if didChange {
                saveAchievements()
            }
        }
    }

    private func achievementIndex(matching title: String) -> Int? {
        let normalizedTitle = normalizedAchievementKey(title)
        return achievements.firstIndex { achievement in
            achievementLookupKeys(for: achievement).contains(normalizedTitle)
        }
    }

    private func achievementLookupKeys(for achievement: Achievement) -> Set<String> {
        let aliases = Self.achievementAliasesByID[achievement.id] ?? []
        let rawValues = [achievement.title] + aliases
        return Set(rawValues.map(normalizedAchievementKey))
    }

    private func normalizedAchievementKey(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func syncHabitAchievements(from habits: [Habit]? = nil) {
        if AppReviewManager.shared.isDemoMode { return }

        let storedHabits = habits ?? loadStoredHabits()
        guard !storedHabits.isEmpty else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let completedToday = storedHabits.filter { habit in
            habit.completionDates.contains { calendar.isDate($0, inSameDayAs: today) }
        }

        markAchievementCompleted(id: "habits.new_beginning")
        updateAchievementProgress(id: "habits.hunter", currentProgress: Double(storedHabits.map(\.streak).max() ?? 0))
        updateAchievementProgress(id: "habits.power_of_10", currentProgress: Double(storedHabits.map { $0.completionDates.count }.max() ?? 0))
        updateAchievementProgress(id: "habits.dont_break_chain", currentProgress: Double(storedHabits.map(\.streak).max() ?? 0))
        updateAchievementProgress(id: "habits.igniter", currentProgress: Double(storedHabits.map(\.streak).max() ?? 0))
        updateAchievementProgress(id: "habits.multitasker", currentProgress: Double(completedToday.count))

        if !storedHabits.isEmpty && completedToday.count == storedHabits.count {
            markAchievementCompleted(id: "habits.perfect_day")
        }

        let morningCompleted = completedToday.filter { $0.category == "Morning" }.count
        updateAchievementProgress(id: "habits.morning_routine", currentProgress: Double(morningCompleted))

        let eveningCompleted = completedToday.filter { $0.category == "Evening" }.count
        updateAchievementProgress(id: "habits.evening_ritual", currentProgress: Double(eveningCompleted))

        let longestStreak = storedHabits.map(\.streak).max() ?? 0
        if longestStreak >= 14 {
            markAchievementCompleted(id: "habits.goal_oriented")
        }
    }

    private func syncMindfulnessAchievements() async {
        if AppReviewManager.shared.isDemoMode { return }

        let sessions = HistoryManager.shared.loadSessions()
        guard !sessions.isEmpty else { return }

        let meditationsByID = Dictionary(uniqueKeysWithValues: allMeditations.map { ($0.id, $0) })
        let completedMeditations = sessions.compactMap { session -> (CompletedSession, Meditation)? in
            guard let meditation = meditationsByID[session.meditationID] else { return nil }
            return (session, meditation)
        }
        let sessionMeditations = completedMeditations.map(\.1)
        let totalMinutes = sessionMeditations.reduce(0) { $0 + $1.durationInMinutes }

        markAchievementCompleted(id: "breathing.first_breath")
        updateAchievementProgress(id: "breathing.deep_breath", currentProgress: Double(sessionMeditations.map(\.durationInMinutes).max() ?? 0))
        updateAchievementProgress(id: "breathing.total_30_min", currentProgress: Double(totalMinutes))
        updateAchievementProgress(id: "breathing.expert", currentProgress: Double(sessions.count))

        let streak = meditationStreak(from: sessions)
        updateAchievementProgress(id: "breathing.streak", currentProgress: Double(streak))

        if sessionMeditations.contains(where: { $0.achievementTags.contains(.calmDown) }) {
            markAchievementCompleted(id: "breathing.calm_down")
        }
        if sessionMeditations.contains(where: { $0.achievementTags.contains(.focus) }) {
            markAchievementCompleted(id: "breathing.focus_session")
        }
        if sessionMeditations.contains(where: { $0.achievementTags.contains(.beforeSleep) }) {
            markAchievementCompleted(id: "breathing.before_sleep")
        }
        if sessionMeditations.contains(where: { $0.achievementTags.contains(.boxBreathing) }) {
            markAchievementCompleted(id: "breathing.box_breathing")
        }

        let workouts = await healthKitManager.fetchWorkouts()
        let workoutEndDates = workouts.map(\.endDate)
        let heartbeatUnlocked = completedMeditations.contains { session, meditation in
            guard meditation.achievementTags.contains(.postWorkoutRecovery) else { return false }
            return workoutEndDates.contains { workoutEnd in
                let delta = session.completionDate.timeIntervalSince(workoutEnd)
                return delta >= 0 && delta <= 2 * 3600
            }
        }
        if heartbeatUnlocked {
            markAchievementCompleted(id: "breathing.heartbeat")
        }
    }

    private func loadStoredHabits() -> [Habit] {
        guard let data = UserDefaults.standard.data(forKey: "habits"),
              let habits = try? JSONDecoder().decode([Habit].self, from: data) else {
            return []
        }
        return habits
    }

    private func meditationStreak(from sessions: [CompletedSession]) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(sessions.map { calendar.startOfDay(for: $0.completionDate) }).sorted(by: >)
        guard let mostRecentDay = uniqueDays.first else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        guard mostRecentDay == today || mostRecentDay == yesterday else { return 0 }

        var streak = 1
        var expectedPreviousDay = calendar.date(byAdding: .day, value: -1, to: mostRecentDay)!
        for day in uniqueDays.dropFirst() {
            if day == expectedPreviousDay {
                streak += 1
                expectedPreviousDay = calendar.date(byAdding: .day, value: -1, to: expectedPreviousDay)!
            } else {
                break
            }
        }
        return streak
    }

    private func sleepConsistencyStreak(from analyses: [DailySleepAnalysis]) -> Int {
        let sortedAnalyses = analyses
            .filter { $0.totalAsleepTime > 0 && $0.dateInterval != nil }
            .sorted(by: { $0.date > $1.date })

        guard let mostRecent = sortedAnalyses.first else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let mostRecentDay = calendar.startOfDay(for: mostRecent.date)
        guard mostRecentDay == today || mostRecentDay == yesterday else { return 0 }

        var streak = 1
        var previousAnalysis = mostRecent
        for analysis in sortedAnalyses.dropFirst() {
            let previousDay = calendar.startOfDay(for: previousAnalysis.date)
            let currentDay = calendar.startOfDay(for: analysis.date)
            guard currentDay == calendar.date(byAdding: .day, value: -1, to: previousDay) else { break }
            guard isSleepTimingConsistent(lhs: previousAnalysis, rhs: analysis) else { break }
            streak += 1
            previousAnalysis = analysis
        }
        return streak
    }

    private func isSleepTimingConsistent(lhs: DailySleepAnalysis, rhs: DailySleepAnalysis) -> Bool {
        guard let lhsInterval = lhs.dateInterval, let rhsInterval = rhs.dateInterval else { return false }

        let bedtimeDelta = abs(minutesSinceStartOfDay(for: lhsInterval.start) - minutesSinceStartOfDay(for: rhsInterval.start))
        let wakeDelta = abs(minutesSinceStartOfDay(for: lhsInterval.end) - minutesSinceStartOfDay(for: rhsInterval.end))
        return bedtimeDelta <= 60 && wakeDelta <= 60
    }

    private func hasSilentSleep(_ analysis: DailySleepAnalysis) -> Bool {
        analysis.stagePeriods.filter { $0.type == .awake }.isEmpty
    }

    private func isPowerNap(_ analysis: DailySleepAnalysis) -> Bool {
        guard let interval = analysis.dateInterval else { return false }
        let durationMinutes = interval.duration / 60
        let hour = Calendar.current.component(.hour, from: interval.start)
        return durationMinutes >= 15 && durationMinutes <= 30 && (12...18).contains(hour)
    }

    private func minutesSinceStartOfDay(for date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[AchievementDebug] \(message)")
#endif
    }

    private func debugPrintCoverageSummary() {
#if DEBUG
        let unlocked = achievements.filter { !$0.isLocked }.count
        let heuristicsRemaining = achievements
            .filter { $0.isLocked && Self.heuristicAchievementIDs.contains($0.id) }
            .map(\.id)
        print("[AchievementDebug] coverage summary: \(unlocked)/\(achievements.count) unlocked, heuristicPending=\(heuristicsRemaining)")
#endif
    }

    private func formatDebug(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

extension Notification.Name {
    static let meditationSessionCompleted = Notification.Name("MeditationSessionCompleted")
}

// MARK: - Struct Definition (Class Dışında)
struct AchievementProgress: Codable {
    let id: String
    var isLocked: Bool
    var progress: Double
}

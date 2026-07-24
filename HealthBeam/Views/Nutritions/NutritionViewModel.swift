import SwiftUI
import HealthKit
import Combine
import SwiftData

@MainActor
class NutritionViewModel: ObservableObject {
    private enum GoalStorageKey {
        static let calories = "nutrition.dailyCalorieGoal"
        static let protein = "nutrition.dailyProteinGoal"
        static let carbs = "nutrition.dailyCarbsGoal"
        static let fat = "nutrition.dailyFatGoal"
        static let water = "nutrition.dailyWaterGoalLiters"
    }

    private let healthKitManager = HealthKitManager.shared

    @Published var todayCaloriesFromHealthKit: Double = 0
    @Published var todayProteinFromHealthKit: Double = 0
    @Published var todayCarbsFromHealthKit: Double = 0
    @Published var todayFatFromHealthKit: Double = 0
    @Published var isLoading = false
    @Published var error: Error?
    @Published var dailyCalorieGoal: Double
    @Published var dailyProteinGoal: Double
    @Published var dailyCarbsGoal: Double
    @Published var dailyFatGoal: Double
    @Published var todayWaterIntakeLiters: Double = 0
    @Published var dailyWaterGoalLiters: Double
    @Published var recentWaterLogs: [WaterLogEntry] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var achievementsViewModel: AchievementsViewModel?

    init() {
        let defaults = UserDefaults.standard
        let storedCalorieGoal = defaults.double(forKey: GoalStorageKey.calories)
        let storedProteinGoal = defaults.double(forKey: GoalStorageKey.protein)
        let storedCarbsGoal = defaults.double(forKey: GoalStorageKey.carbs)
        let storedFatGoal = defaults.double(forKey: GoalStorageKey.fat)
        let storedWaterGoal = defaults.double(forKey: GoalStorageKey.water)

        self.dailyCalorieGoal = storedCalorieGoal > 0 ? storedCalorieGoal : 2000
        self.dailyProteinGoal = storedProteinGoal > 0 ? storedProteinGoal : 150
        self.dailyCarbsGoal = storedCarbsGoal > 0 ? storedCarbsGoal : 225
        self.dailyFatGoal = storedFatGoal > 0 ? storedFatGoal : 67
        self.dailyWaterGoalLiters = storedWaterGoal > 0 ? storedWaterGoal : 2.0

        fetchTodaysNutritionFromHealthKit()
        
        // Timer ile periyodik güncelleme
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.fetchTodaysNutritionFromHealthKit() }
            .store(in: &cancellables)
            
        Task {
            await fetchTodaysWaterIntake()
            await fetchRecentWaterLogs()
        }
    }
    
    func setup(achievementsViewModel: AchievementsViewModel) {
        self.achievementsViewModel = achievementsViewModel
    }

    func updateDailyGoals(calories: Double, protein: Double, carbs: Double, fat: Double, water: Double) {
        dailyCalorieGoal = calories
        dailyProteinGoal = protein
        dailyCarbsGoal = carbs
        dailyFatGoal = fat
        dailyWaterGoalLiters = water

        let defaults = UserDefaults.standard
        defaults.set(calories, forKey: GoalStorageKey.calories)
        defaults.set(protein, forKey: GoalStorageKey.protein)
        defaults.set(carbs, forKey: GoalStorageKey.carbs)
        defaults.set(fat, forKey: GoalStorageKey.fat)
        defaults.set(water, forKey: GoalStorageKey.water)
    }
    
    func fetchTodaysNutritionFromHealthKit() {
        // MARK: - Demo Modu Kontrolü
        if AppReviewManager.shared.isDemoMode {
            // Demo modunda HealthKit verisi yerine 0 dönüyoruz.
            // Çünkü View tarafında Mock Yemekler zaten toplanacak.
            // Eğer buraya da mock veri eklersek toplamlar iki katına çıkar.
            self.todayCaloriesFromHealthKit = 0
            self.todayProteinFromHealthKit = 0
            self.todayCarbsFromHealthKit = 0
            self.todayFatFromHealthKit = 0
            self.isLoading = false
            return
        }

        isLoading = true
        error = nil
        Task {
            do {
                todayCaloriesFromHealthKit = await healthKitManager.fetchTodaysSum(for: .dietaryEnergyConsumed, unit: .kilocalorie())
                todayProteinFromHealthKit = await healthKitManager.fetchTodaysSum(for: .dietaryProtein, unit: .gram())
                todayCarbsFromHealthKit = await healthKitManager.fetchTodaysSum(for: .dietaryCarbohydrates, unit: .gram())
                todayFatFromHealthKit = await healthKitManager.fetchTodaysSum(for: .dietaryFatTotal, unit: .gram())
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }

    func fetchTodaysWaterIntake() async {
        // MARK: - Demo Modu: Su Toplamı
        if AppReviewManager.shared.isDemoMode {
            let total = MockNutrition.sampleWaterLogs.reduce(0) { $0 + $1.amountLiters }
            // Eğer kullanıcı demo modunda ekleme yaptıysa onu da hesaba kat (recentLogs üzerinden)
            // Ancak basitlik adına MockData + memorydeki recentLogs'un toplamını alabiliriz.
            // Şimdilik sadece mock veriyi baz alıyoruz, logWater demo mantığı aşağıda.
            await MainActor.run {
                // Eğer daha önce belleğe eklenmiş kayıtlar varsa (Mock harici) onları korumak için
                // bu basit örnekte direkt mock veriyi set ediyoruz.
                self.todayWaterIntakeLiters = total
            }
            return
        }
        
        self.todayWaterIntakeLiters = await healthKitManager.fetchTodaysWaterIntake()
    }
    
    func logWater(liters: Double) async {
        guard liters > 0 else { return }

        // MARK: - Demo Modu: Su Ekleme
        if AppReviewManager.shared.isDemoMode {
            let newLog = WaterLogEntry(id: UUID(), amountLiters: liters, date: Date())
            await MainActor.run {
                self.recentWaterLogs.insert(newLog, at: 0)
                self.todayWaterIntakeLiters += liters
            }
            return
        }

        let newLog = WaterLogEntry(id: UUID(), amountLiters: liters, date: Date())

        do {
            recentWaterLogs.insert(newLog, at: 0)
            todayWaterIntakeLiters += liters

            try await healthKitManager.requestAuthorization()
            try await healthKitManager.saveWaterIntake(liters: liters)
            await refreshWaterTracking()
            await achievementsViewModel?.checkHealthKitAchievements()
        } catch {
            print("❌ Su kaydedilirken hata oluştu: \(error.localizedDescription)")
            self.error = error
            recentWaterLogs.removeAll { $0.id == newLog.id }
            todayWaterIntakeLiters = max(0, todayWaterIntakeLiters - liters)
        }
    }
    
    func fetchRecentWaterLogs() async {
        // MARK: - Demo Modu: Su Geçmişi
        if AppReviewManager.shared.isDemoMode {
            await MainActor.run {
                // Mock verileri tarihe göre sırala
                self.recentWaterLogs = MockNutrition.sampleWaterLogs.sorted(by: { $0.date > $1.date })
            }
            return
        }
        
        self.recentWaterLogs = await healthKitManager.fetchRecentWaterSamples()
    }
    
    func deleteWaterLog(logToDelete: WaterLogEntry) async {
        // MARK: - Demo Modu: Su Silme
        if AppReviewManager.shared.isDemoMode {
            await MainActor.run {
                self.recentWaterLogs.removeAll { $0.id == logToDelete.id }
                self.todayWaterIntakeLiters -= logToDelete.amountLiters
                if self.todayWaterIntakeLiters < 0 { self.todayWaterIntakeLiters = 0 }
            }
            return
        }

        await healthKitManager.deleteWaterSample(uuid: logToDelete.id)
        recentWaterLogs.removeAll { $0.id == logToDelete.id }
        await refreshWaterTracking()
        await achievementsViewModel?.checkHealthKitAchievements()
    }

    func refreshWaterTracking() async {
        await fetchTodaysWaterIntake()
        await fetchRecentWaterLogs()
    }

    func addLog(from food: FoodItem, mealType: MealType, grams: Int, modelContext: ModelContext) {
        // Demo modunda yemek ekleme şu an SwiftData'ya yazıyor.
        // İstenirse buraya da engel konabilir ama Reviewer yemek eklemeyi test etmek isteyebilir.
        // O yüzden burayı orjinal bırakıyoruz, SwiftData local container'a yazar.
        
        let caloriesPer100g = food.nutrients.energyKcal
        let proteinPer100g = food.nutrients.protein
        let fatPer100g = food.nutrients.fat
        let carbsPer100g = food.nutrients.carbs
        let sugarPer100g = food.nutrients.sugar ?? 0.0

        let multiplier = Double(grams) / 100.0
        let newMeal = Meal(
            id: UUID(),
            name: food.label,
            calories: caloriesPer100g * multiplier,
            protein: proteinPer100g * multiplier,
            carbs: carbsPer100g * multiplier,
            fat: fatPer100g * multiplier,
            sugar: sugarPer100g * multiplier,
            time: .now,
            mealType: mealType,
            isManualEntry: false,
            tags: ["🤖 Beam AI"]
        )
        modelContext.insert(newMeal)
        saveMealToHealthKit(meal: newMeal)
        fetchTodaysNutritionFromHealthKit()
        do {
            let allMeals = try modelContext.fetch(FetchDescriptor<Meal>())
            checkAchievementsAfterAdding(meal: newMeal, allMeals: allMeals, modelContext: modelContext)
        } catch {
        }
    }

    func saveMealToHealthKit(meal: Meal) {
        if AppReviewManager.shared.isDemoMode { return } // Demo modunda HealthKit'e yazma
        Task {
            await healthKitManager.saveMealToHealthKit(meal)
        }
    }

    func deleteMeal(_ meal: Meal, modelContext: ModelContext) async {
        if AppReviewManager.shared.isDemoMode {
            // Demo modunda mock veriyi silemeyiz (SwiftData context'te değil), hata vermemesi için return.
            // Eğer yemek sonradan eklendiyse silinebilir ama MockNutrition içinden geliyorsa silinemez.
            // Basitlik adına demo modunda silmeyi pas geçiyoruz.
            return
        }
        await healthKitManager.deleteMealFromHealthKit(meal: meal)
        modelContext.delete(meal)
        fetchTodaysNutritionFromHealthKit()
    }

    func checkAchievementsAfterAdding(meal: Meal, allMeals: [Meal], modelContext: ModelContext) {

        let todaysMeals = allMeals.filter { Calendar.current.isDateInToday($0.time) }
        if isHealthyMeal(meal) {
            achievementsViewModel?.userCompletedAction(achievementTitle: "Healthy Meal")
        }

        if meal.isManualEntry {
            achievementsViewModel?.userCompletedAction(achievementTitle: "Home Cook")
        }

        let totalProteinToday = todayProteinFromHealthKit + todaysMeals.reduce(0) { $0 + $1.protein }
        if totalProteinToday >= dailyProteinGoal {
            achievementsViewModel?.userCompletedAction(achievementTitle: "Protein Boost")
        }

        let uniqueDays = Set(allMeals.map { Calendar.current.startOfDay(for: $0.time) }).sorted(by: >)
        var streak = 0
        if !uniqueDays.isEmpty {
            var currentDate = uniqueDays.first!
            streak = 1
            if uniqueDays.count > 1 {
                for i in 1..<uniqueDays.count {
                    let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
                    if uniqueDays.contains(previousDay) && uniqueDays[i] == previousDay {
                        streak += 1
                        currentDate = previousDay
                    } else {
                        break
                    }
                }
            }
        }
        if streak >= 3 {
            achievementsViewModel?.userCompletedAction(achievementTitle: "Meal Diary")
        }

        checkOmega3Achievement(allMeals: allMeals)
        checkRainbowPlateAchievement(todaysMeals: todaysMeals)
        checkNoJunkFoodAchievement(allMeals: allMeals)
        checkSugarFreeDayAchievement(modelContext: modelContext)
    }


    private func checkOmega3Achievement(allMeals: [Meal]) {
        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }
        let fishMealsInLastWeek = allMeals.filter { meal in
            guard meal.time >= sevenDaysAgo else { return false }
            return meal.tags?.contains("🐟 Fish") == true
        }
        if fishMealsInLastWeek.count >= 2 {
            achievementsViewModel?.userCompletedAction(achievementTitle: "Omega-3 Supplement")
        }
    }

    private func checkRainbowPlateAchievement(todaysMeals: [Meal]) {
        let detectedColors = Set(todaysMeals.flatMap { colorSignals(for: $0) })
        if detectedColors.count >= 5 {
            achievementsViewModel?.userCompletedAction(achievementTitle: "Rainbow Plate")
        }
    }

    private func checkNoJunkFoodAchievement(allMeals: [Meal]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var consecutiveDaysWithoutJunk = 0
        for i in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { break }
            let mealsOnDate = allMeals.filter { calendar.isDate($0.time, inSameDayAs: date) }
            if mealsOnDate.isEmpty { continue }
            let hasJunkFood = mealsOnDate.contains { $0.tags?.contains("🍟 Junk Food") == true }
            if !hasJunkFood {
                consecutiveDaysWithoutJunk += 1
            } else {
                consecutiveDaysWithoutJunk = 0
                break
            }
        }
        if consecutiveDaysWithoutJunk >= 3 {
            achievementsViewModel?.userCompletedAction(achievementTitle: "Say No to Junk Food")
        }
    }

    private func checkSugarFreeDayAchievement(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }
        let predicate = #Predicate<Meal> { meal in
            meal.time >= yesterday && meal.time < today
        }
        let fetchDescriptor = FetchDescriptor<Meal>(predicate: predicate)
        do {
            let yesterdaysMeals = try modelContext.fetch(fetchDescriptor)
            guard !yesterdaysMeals.isEmpty else { return }
            let totalSugarYesterday = yesterdaysMeals.reduce(0) { $0 + $1.sugar }
            if totalSugarYesterday == 0 {
                achievementsViewModel?.userCompletedAction(achievementTitle: "Sugar-Free Day")
            }
        } catch {
        }
    }

    private func isHealthyMeal(_ meal: Meal) -> Bool {
        let normalizedTags = Set((meal.tags ?? []).map(normalizeToken))
        let healthyTagSignals: Set<String> = [
            "healthy", "vegetable", "vegetables", "fruit", "fruits", "fish",
            "white meat", "high protein", "omega 3", "omega-3", "salad"
        ]

        if !normalizedTags.isDisjoint(with: healthyTagSignals) {
            return true
        }

        let normalizedName = normalizeToken(meal.name)
        let healthyNameSignals = ["salad", "salmon", "oatmeal", "quinoa", "chicken", "fruit", "vegetable"]
        if healthyNameSignals.contains(where: normalizedName.contains) {
            return true
        }

        return meal.protein >= 20 && meal.sugar <= 12
    }

    private func colorSignals(for meal: Meal) -> Set<String> {
        let source = ([meal.name] + (meal.tags ?? []))
            .map(normalizeToken)
            .joined(separator: " ")

        var colors = Set<String>()
        let colorKeywords: [String: [String]] = [
            "red": ["strawberry", "apple", "tomato", "pepper", "beet", "cherry", "raspberry"],
            "orange": ["orange", "carrot", "pumpkin", "sweet potato", "apricot", "mango"],
            "yellow": ["banana", "corn", "pineapple", "lemon", "yellow pepper"],
            "green": ["spinach", "broccoli", "avocado", "kiwi", "salad", "cucumber", "leaf", "healthy"],
            "blue": ["blueberry", "blackberry"],
            "purple": ["eggplant", "grape", "plum", "purple cabbage"]
        ]

        for (color, keywords) in colorKeywords where keywords.contains(where: source.contains) {
            colors.insert(color)
        }

        return colors
    }

    private func normalizeToken(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "🥦", with: "")
            .replacingOccurrences(of: "🥕", with: "")
            .replacingOccurrences(of: "🍓", with: "")
            .replacingOccurrences(of: "🐟", with: "")
            .replacingOccurrences(of: "🍗", with: "")
            .replacingOccurrences(of: "🍟", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

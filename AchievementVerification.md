# Achievement Verification Matrix

This file maps every achievement to its current trigger source in code.

Heuristic means the app uses a reasonable implementation rule because the achievement text is broader than the concrete data available.

## Workouts

- `workouts.first_steps` / `First Steps`: `AchievementsViewModel.checkHealthKitAchievements()` unlocks when total workout count is greater than `0`.
- `workouts.warm_up` / `Warm-Up Round`: `AchievementsViewModel.checkHealthKitAchievements()` uses total calories burned across all workouts.
- `workouts.5k_runner` / `5K Runner`: `AchievementsViewModel.checkHealthKitAchievements()` uses max workout distance from HealthKit.
- `workouts.one_hour_resistance` / `One Hour of Resistance`: `AchievementsViewModel.checkHealthKitAchievements()` uses longest workout duration from HealthKit.
- `workouts.calorie_monster` / `Calorie Monster`: `AchievementsViewModel.checkHealthKitAchievements()` uses highest calories burned in a single workout.
- `workouts.weekly_streak` / `Weekly Streak`: `AchievementsViewModel.checkHealthKitAchievements()` uses current workout streak from HealthKit.
- `workouts.guru` / `Workout Guru`: `AchievementsViewModel.checkHealthKitAchievements()` uses total workout count from HealthKit.
- `workouts.night_owl` / `Night Owl`: `AchievementsViewModel.checkHealthKitAchievements()` unlocks if any workout happened after `22:00`.
- `workouts.strength_starter` / `Strength Starter`: `AchievementsViewModel.checkHealthKitAchievements()` unlocks if HealthKit contains a traditional strength training workout.
- `workouts.explorer` / `Explorer`: `AchievementsViewModel.checkHealthKitAchievements()` uses max daily step count from HealthKit history.

## Nutrition

- `nutrition.healthy_meal` / `Healthy Meal`: `NutritionViewModel.checkAchievementsAfterAdding()` unlocks when a meal includes a healthy tag. Heuristic.
- `nutrition.water_champion` / `Water Champion`: `AchievementsViewModel.checkHealthKitAchievements()` uses today’s water intake from HealthKit.
- `nutrition.rainbow_plate` / `Rainbow Plate`: `NutritionViewModel.checkRainbowPlateAchievement()` unlocks when today’s meal tags contain at least `5` unique values. Heuristic.
- `nutrition.omega3_supp` / `Omega-3 Supplement`: `NutritionViewModel.checkOmega3Achievement()` unlocks when at least `2` fish meals exist in the last `7` days.
- `nutrition.sugar_free_day` / `Sugar-Free Day`: `NutritionViewModel.checkSugarFreeDayAchievement()` unlocks when yesterday’s logged meals sum to `0` sugar.
- `nutrition.food_diary` / `Food Diary`: `NutritionViewModel.checkAchievementsAfterAdding()` unlocks on a `3` day meal logging streak.
- `nutrition.home_cook` / `Home Cook`: `NutritionViewModel.checkAchievementsAfterAdding()` unlocks on manual meal entry.
- `nutrition.protein_power` / `Protein Power`: `NutritionViewModel.checkAchievementsAfterAdding()` unlocks when daily protein meets `dailyProteinGoal`.
- `nutrition.meal_planner` / `Meal Planner`: `PlanMealSheet.savePlan()` unlocks when a meal plan is saved.
- `nutrition.no_junk_food` / `No Junk Food`: `NutritionViewModel.checkNoJunkFoodAchievement()` unlocks after `3` consecutive days without junk food tags.

## Sleep

- `sleep.good_night` / `Good Night Sleep`: `AchievementsViewModel.checkHealthKitAchievements()` uses last night sleep duration.
- `sleep.golden_hours` / `Golden Hours`: `AchievementsViewModel.checkHealthKitAchievements()` unlocks if sleep start hour is before `23`.
- `sleep.early_riser` / `Early Riser`: `AchievementsViewModel.checkHealthKitAchievements()` unlocks if wake hour is before `7`.
- `sleep.quality_sleep` / `Quality Sleep`: `AchievementsViewModel.checkHealthKitAchievements()` unlocks if computed sleep score is at least `85`.
- `sleep.uninterrupted` / `Uninterrupted Night`: `AchievementsViewModel.checkHealthKitAchievements()` unlocks if awake segment count is at most `1`.
- `sleep.consistent_pattern` / `Consistent Pattern`: `AchievementsViewModel.sleepConsistencyStreak()` requires a `7` day streak where bedtime and wake time stay within `1` hour day to day. Heuristic.
- `sleep.goal_streak` / `Sleep Goal Streak`: `AchievementsViewModel.checkHealthKitAchievements()` uses `HealthKitManager.fetchSleepStreak(sleepGoalInHours: 7.0)`.
- `sleep.silent_environment` / `Silent Environment`: `AchievementsViewModel.hasSilentSleep(_:)` unlocks if a sleep analysis contains no awake segments. Heuristic.
- `sleep.deep_sleeper` / `Deep Sleeper`: `AchievementsViewModel.checkHealthKitAchievements()` uses deep sleep minutes from the latest analysis.
- `sleep.power_nap` / `Power Nap`: `AchievementsViewModel.isPowerNap(_:)` unlocks for a `15` to `30` minute sleep session starting between `12:00` and `18:00`. Heuristic.

## Habits

- `habits.hunter` / `Habit Hunter`: `AchievementsViewModel.syncHabitAchievements()` uses the highest saved habit streak.
- `habits.perfect_day` / `Perfect Day`: `AchievementsViewModel.syncHabitAchievements()` unlocks when all saved habits are completed today.
- `habits.power_of_10` / `Power of 10`: `AchievementsViewModel.syncHabitAchievements()` uses the highest completion count on any saved habit.
- `habits.dont_break_chain` / `Don’t Break the Chain`: `AchievementsViewModel.syncHabitAchievements()` uses the highest saved habit streak.
- `habits.new_beginning` / `A New Beginning`: `AchievementsViewModel.syncHabitAchievements()` unlocks once at least one habit exists.
- `habits.morning_routine` / `Morning Routine`: `AchievementsViewModel.syncHabitAchievements()` uses today’s completed habits in the `Morning` category.
- `habits.evening_ritual` / `Evening Ritual`: `AchievementsViewModel.syncHabitAchievements()` uses today’s completed habits in the `Evening` category.
- `habits.igniter` / `Igniter`: `AchievementsViewModel.syncHabitAchievements()` uses the highest saved habit streak.
- `habits.goal_oriented` / `Goal-Oriented`: `AchievementsViewModel.syncHabitAchievements()` unlocks when any habit streak reaches `14`. Heuristic.
- `habits.multitasker` / `Multitasker`: `AchievementsViewModel.syncHabitAchievements()` uses the count of distinct habits completed today.

## Journaling

- `journaling.first_page` / `First Page`: `AddEditJournalEntryViews.saveJournalEntry()` unlocks when any journal entry is saved.
- `journaling.daily_streak` / `Daily Streak`: `AddEditJournalEntryViews.saveJournalEntry()` unlocks on a `3` day journal streak.
- `journaling.gratitude` / `Gratitude`: `AddEditJournalEntryViews.saveJournalEntry()` unlocks when text contains gratitude keywords.
- `journaling.deep_thought` / `Deep Thought`: `AddEditJournalEntryViews.saveJournalEntry()` unlocks when text length is at least `250`.
- `journaling.mood_tracker` / `Mood Tracker`: `AddEditJournalEntryViews.saveJournalEntry()` unlocks on a `7` day mood logging streak.
- `journaling.capture_moment` / `Capture the Moment`: `AddEditJournalEntryViews.saveJournalEntry()` unlocks when an image block exists.
- `journaling.set_goals` / `Set Goals`: `AddEditJournalEntryViews.saveJournalEntry()` unlocks when text contains goal keywords.
- `journaling.brainstorm` / `Brainstorm`: `AddEditJournalEntryViews.saveJournalEntry()` unlocks when text contains brainstorm keywords or reaches `350` characters.
- `journaling.monthly_writer` / `Monthly Writer`: `AddEditJournalEntryViews.saveJournalEntry()` unlocks when the current month reaches `10` entries.
- `journaling.look_back` / `Looking Back`: `JournalEntryDetailView.onAppear` unlocks when viewing an entry older than `30` days.

## Breathing

- `breathing.first_breath` / `First Breath`: `AchievementsViewModel.syncMindfulnessAchievements()` unlocks once at least one completed meditation session exists.
- `breathing.deep_breath` / `Deep Breath`: `AchievementsViewModel.syncMindfulnessAchievements()` uses the longest meditation duration completed.
- `breathing.calm_down` / `Calm Down Break`: `AchievementsViewModel.syncMindfulnessAchievements()` unlocks when any completed meditation belongs to `Inner Peace and Calmness`. Heuristic.
- `breathing.focus_session` / `Focus Session`: `AchievementsViewModel.syncMindfulnessAchievements()` unlocks when any completed meditation belongs to `Energy and Focus`. Heuristic.
- `breathing.before_sleep` / `Before Sleep`: `AchievementsViewModel.syncMindfulnessAchievements()` unlocks when any completed meditation belongs to `Relaxing Sleep`. Heuristic.
- `breathing.streak` / `Breathing Streak`: `AchievementsViewModel.syncMindfulnessAchievements()` uses the meditation day streak from `HistoryManager`.
- `breathing.total_30_min` / `Total 30 Minutes`: `AchievementsViewModel.syncMindfulnessAchievements()` uses total completed meditation minutes.
- `breathing.box_breathing` / `Box Breathing`: `AchievementsViewModel.syncMindfulnessAchievements()` unlocks when a completed meditation title contains `breath`. Heuristic.
- `breathing.heartbeat` / `Heartbeat`: `AchievementsViewModel.syncMindfulnessAchievements()` unlocks when a meditation session is completed within `2` hours after a workout end time. Heuristic.
- `breathing.expert` / `Breathing Expert`: `AchievementsViewModel.syncMindfulnessAchievements()` uses total meditation session count.

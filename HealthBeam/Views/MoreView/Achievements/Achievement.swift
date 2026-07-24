import Foundation
import SwiftUI

enum AchievementCategory: String, Codable, CaseIterable, Identifiable {
    case workouts, nutrition, sleep, habits, journaling, breathing
    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .workouts: return String(localized: "Workouts")
        case .nutrition: return String(localized: "Nutrition")
        case .sleep: return String(localized: "Sleep")
        case .habits: return String(localized: "Habits")
        case .journaling: return String(localized: "Journaling")
        case .breathing: return String(localized: "Breathing")
        }
    }

    var color: Color {
        switch self {
        case .workouts: return .red
        case .nutrition: return .green
        case .sleep: return .indigo
        case .habits: return .blue
        case .journaling: return .purple
        case .breathing: return .teal
        }
    }
}
struct Achievement: Codable, Identifiable {
    let id: String
    let category: AchievementCategory
    let icon: String
    let title: String
    let description: String
    var isLocked: Bool
    var progress: Double
    let goal: Double
    var color: Color { category.color }
    var localizedTitle: String { String(localized: String.LocalizationValue(title)) }
    var localizedDescription: String { String(localized: String.LocalizationValue(description)) }
}

private enum AchievementLocalizationCatalog {
    // Keeps achievement title/description literals in a localizable context so Xcode
    // exports them to the string catalog while the model continues to use stable IDs.
    static let strings: [LocalizedStringResource] = [
        "First Steps", "Complete your first workout.",
        "Warm-Up Round", "Burn a total of 1000 calories.",
        "5K Runner", "Run 5 kilometers in one session.",
        "One Hour of Resistance", "Complete a 60-minute workout.",
        "Calorie Monster", "Burn 500 calories in a single workout.",
        "Weekly Streak", "Work out every day for one week.",
        "Workout Guru", "Complete a total of 50 workouts.",
        "Night Owl", "Complete a workout after 10 PM.",
        "Strength Starter", "Do your first weight training workout.",
        "Explorer", "Take 10,000 steps in a single day.",

        "Healthy Meal", "Log your first healthy meal.",
        "Water Champion", "Drink 8 glasses of water in one day.",
        "Rainbow Plate", "Eat 5 different colored fruits/vegetables in a day.",
        "Omega-3 Supplement", "Eat fish twice a week.",
        "Sugar-Free Day", "Go a full day without refined sugar.",
        "Food Diary", "Log all your meals for 3 days.",
        "Home Cook", "Cook your own healthy meal.",
        "Protein Power", "Hit your daily protein target.",
        "Meal Planner", "Create a one-week meal plan.",
        "No Junk Food", "Avoid junk food for 3 days.",

        "Good Night Sleep", "Sleep 7 hours in one night.",
        "Golden Hours", "Go to bed before 11 PM.",
        "Early Riser", "Wake up before 7 AM.",
        "Quality Sleep", "Achieve a high sleep quality score.",
        "Uninterrupted Night", "Sleep through the night without waking up.",
        "Consistent Pattern", "Go to bed and wake up at the same time for a week.",
        "Sleep Goal Streak", "Hit your sleep goal 3 nights in a row.",
        "Silent Environment", "Fall asleep in a quiet environment.",
        "Deep Sleeper", "Get 90 minutes of deep sleep in one night.",
        "Power Nap", "Take a 20-minute nap.",

        "Habit Hunter", "Maintain a habit for 3 days.",
        "Perfect Day", "Complete all your habits in one day.",
        "Power of 10", "Complete a habit 10 times.",
        "Don’t Break the Chain", "Maintain a 7-day streak for a habit.",
        "A New Beginning", "Create a new habit.",
        "Morning Routine", "Complete 3 morning habits.",
        "Evening Ritual", "Complete 3 evening habits.",
        "Igniter", "Maintain a habit for a month.",
        "Goal-Oriented", "Achieve a difficult habit goal.",
        "Multitasker", "Complete 5 different habits in one day.",

        "First Page", "Write your first journal entry.",
        "Daily Streak", "Write a journal entry 3 days in a row.",
        "Gratitude", "Write a gratitude list.",
        "Deep Thought", "Write an entry with more than 250 words.",
        "Mood Tracker", "Track your mood for one week.",
        "Capture the Moment", "Add a photo to an entry.",
        "Set Goals", "Write your goals in your journal.",
        "Brainstorm", "Free-write on a topic.",
        "Monthly Writer", "Create 10 entries in a month.",
        "Looking Back", "Read an old entry and reflect on it.",

        "First Breath", "Complete your first breathing exercise.",
        "Deep Breath", "Do a 5-minute breathing session.",
        "Calm Down Break", "Use a breathing exercise during a stressful moment.",
        "Focus Session", "Do a focus session before starting work.",
        "Before Sleep", "Do a relaxation session before bedtime.",
        "Breathing Streak", "Do a breathing exercise 3 days in a row.",
        "Total 30 Minutes", "Accumulate 30 minutes of breathing exercises.",
        "Box Breathing", "Try the box breathing technique.",
        "Heartbeat", "Lower your heartbeat after exercise.",
        "Breathing Expert", "Complete a total of 25 breathing sessions."
    ]
}

extension Achievement {
    static var mockData: [Achievement] = [
        
        Achievement(id: "workouts.first_steps", category: .workouts, icon: "figure.walk", title: "First Steps", description: "Complete your first workout.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "workouts.warm_up", category: .workouts, icon: "flame.fill", title: "Warm-Up Round", description: "Burn a total of 1000 calories.", isLocked: true, progress: 0, goal: 1000),
        Achievement(id: "workouts.5k_runner", category: .workouts, icon: "figure.run", title: "5K Runner", description: "Run 5 kilometers in one session.", isLocked: true, progress: 0, goal: 5),
        Achievement(id: "workouts.one_hour_resistance", category: .workouts, icon: "timer", title: "One Hour of Resistance", description: "Complete a 60-minute workout.", isLocked: true, progress: 0, goal: 60),
        Achievement(id: "workouts.calorie_monster", category: .workouts, icon: "flame", title: "Calorie Monster", description: "Burn 500 calories in a single workout.", isLocked: true, progress: 0, goal: 500),
        Achievement(id: "workouts.weekly_streak", category: .workouts, icon: "calendar", title: "Weekly Streak", description: "Work out every day for one week.", isLocked: true, progress: 0, goal: 7),
        Achievement(id: "workouts.guru", category: .workouts, icon: "trophy.fill", title: "Workout Guru", description: "Complete a total of 50 workouts.", isLocked: true, progress: 0, goal: 50),
        Achievement(id: "workouts.night_owl", category: .workouts, icon: "moon.fill", title: "Night Owl", description: "Complete a workout after 10 PM.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "workouts.strength_starter", category: .workouts, icon: "figure.strengthtraining.traditional", title: "Strength Starter", description: "Do your first weight training workout.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "workouts.explorer", category: .workouts, icon: "figure.walk", title: "Explorer", description: "Take 10,000 steps in a single day.", isLocked: true, progress: 0, goal: 10000),

        Achievement(id: "nutrition.healthy_meal", category: .nutrition, icon: "leaf.fill", title: "Healthy Meal", description: "Log your first healthy meal.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "nutrition.water_champion", category: .nutrition, icon: "drop.fill", title: "Water Champion", description: "Drink 8 glasses of water in one day.", isLocked: true, progress: 0, goal: 8),
        Achievement(id: "nutrition.rainbow_plate", category: .nutrition, icon: "carrot.fill", title: "Rainbow Plate", description: "Eat 5 different colored fruits/vegetables in a day.", isLocked: true, progress: 0, goal: 5),
        Achievement(id: "nutrition.omega3_supp", category: .nutrition, icon: "fish.fill", title: "Omega-3 Supplement", description: "Eat fish twice a week.", isLocked: true, progress: 0, goal: 2),
        Achievement(id: "nutrition.sugar_free_day", category: .nutrition, icon: "cup.and.saucer.fill", title: "Sugar-Free Day", description: "Go a full day without refined sugar.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "nutrition.food_diary", category: .nutrition, icon: "doc.text", title: "Food Diary", description: "Log all your meals for 3 days.", isLocked: true, progress: 0, goal: 3),
        Achievement(id: "nutrition.home_cook", category: .nutrition, icon: "fork.knife", title: "Home Cook", description: "Cook your own healthy meal.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "nutrition.protein_power", category: .nutrition, icon: "p.circle.fill", title: "Protein Power", description: "Hit your daily protein target.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "nutrition.meal_planner", category: .nutrition, icon: "calendar.badge.clock", title: "Meal Planner", description: "Create a one-week meal plan.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "nutrition.no_junk_food", category: .nutrition, icon: "circle.grid.cross.fill", title: "No Junk Food", description: "Avoid junk food for 3 days.", isLocked: true, progress: 0, goal: 3),

        Achievement(id: "sleep.good_night", category: .sleep, icon: "bed.double.fill", title: "Good Night Sleep", description: "Sleep 7 hours in one night.", isLocked: true, progress: 0, goal: 7),
        Achievement(id: "sleep.golden_hours", category: .sleep, icon: "clock.fill", title: "Golden Hours", description: "Go to bed before 11 PM.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "sleep.early_riser", category: .sleep, icon: "sun.max.fill", title: "Early Riser", description: "Wake up before 7 AM.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "sleep.quality_sleep", category: .sleep, icon: "waveform.path.ecg", title: "Quality Sleep", description: "Achieve a high sleep quality score.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "sleep.uninterrupted", category: .sleep, icon: "zzz", title: "Uninterrupted Night", description: "Sleep through the night without waking up.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "sleep.consistent_pattern", category: .sleep, icon: "calendar", title: "Consistent Pattern", description: "Go to bed and wake up at the same time for a week.", isLocked: true, progress: 0, goal: 7),
        Achievement(id: "sleep.goal_streak", category: .sleep, icon: "star.fill", title: "Sleep Goal Streak", description: "Hit your sleep goal 3 nights in a row.", isLocked: true, progress: 0, goal: 3),
        Achievement(id: "sleep.silent_environment", category: .sleep, icon: "speaker.slash.fill", title: "Silent Environment", description: "Fall asleep in a quiet environment.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "sleep.deep_sleeper", category: .sleep, icon: "moon.stars.fill", title: "Deep Sleeper", description: "Get 90 minutes of deep sleep in one night.", isLocked: true, progress: 0, goal: 90),
        Achievement(id: "sleep.power_nap", category: .sleep, icon: "powersleep", title: "Power Nap", description: "Take a 20-minute nap.", isLocked: true, progress: 0, goal: 1),

        Achievement(id: "habits.hunter", category: .habits, icon: "checkmark.seal.fill", title: "Habit Hunter", description: "Maintain a habit for 3 days.", isLocked: true, progress: 0, goal: 3),
        Achievement(id: "habits.perfect_day", category: .habits, icon: "checklist", title: "Perfect Day", description: "Complete all your habits in one day.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "habits.power_of_10", category: .habits, icon: "goforward.10", title: "Power of 10", description: "Complete a habit 10 times.", isLocked: true, progress: 0, goal: 10),
        Achievement(id: "habits.dont_break_chain", category: .habits, icon: "link", title: "Don’t Break the Chain", description: "Maintain a 7-day streak for a habit.", isLocked: true, progress: 0, goal: 7),
        Achievement(id: "habits.new_beginning", category: .habits, icon: "plus.app.fill", title: "A New Beginning", description: "Create a new habit.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "habits.morning_routine", category: .habits, icon: "sunrise.fill", title: "Morning Routine", description: "Complete 3 morning habits.", isLocked: true, progress: 0, goal: 3),
        Achievement(id: "habits.evening_ritual", category: .habits, icon: "sunset.fill", title: "Evening Ritual", description: "Complete 3 evening habits.", isLocked: true, progress: 0, goal: 3),
        Achievement(id: "habits.igniter", category: .habits, icon: "flame.circle.fill", title: "Igniter", description: "Maintain a habit for a month.", isLocked: true, progress: 0, goal: 30),
        Achievement(id: "habits.goal_oriented", category: .habits, icon: "target", title: "Goal-Oriented", description: "Achieve a difficult habit goal.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "habits.multitasker", category: .habits, icon: "person.3.fill", title: "Multitasker", description: "Complete 5 different habits in one day.", isLocked: true, progress: 0, goal: 5),

        Achievement(id: "journaling.first_page", category: .journaling, icon: "pencil.and.scribble", title: "First Page", description: "Write your first journal entry.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "journaling.daily_streak", category: .journaling, icon: "text.book.closed.fill", title: "Daily Streak", description: "Write a journal entry 3 days in a row.", isLocked: true, progress: 0, goal: 3),
        Achievement(id: "journaling.gratitude", category: .journaling, icon: "hand.thumbsup.fill", title: "Gratitude", description: "Write a gratitude list.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "journaling.deep_thought", category: .journaling, icon: "text.magnifyingglass", title: "Deep Thought", description: "Write an entry with more than 250 words.", isLocked: true, progress: 0, goal: 250),
        Achievement(id: "journaling.mood_tracker", category: .journaling, icon: "face.smiling.fill", title: "Mood Tracker", description: "Track your mood for one week.", isLocked: true, progress: 0, goal: 7),
        Achievement(id: "journaling.capture_moment", category: .journaling, icon: "photo.fill.on.rectangle.fill", title: "Capture the Moment", description: "Add a photo to an entry.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "journaling.set_goals", category: .journaling, icon: "list.bullet.clipboard.fill", title: "Set Goals", description: "Write your goals in your journal.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "journaling.brainstorm", category: .journaling, icon: "brain.head.profile", title: "Brainstorm", description: "Free-write on a topic.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "journaling.monthly_writer", category: .journaling, icon: "calendar", title: "Monthly Writer", description: "Create 10 entries in a month.", isLocked: true, progress: 0, goal: 10),
        Achievement(id: "journaling.look_back", category: .journaling, icon: "arrow.uturn.backward.circle.fill", title: "Looking Back", description: "Read an old entry and reflect on it.", isLocked: true, progress: 0, goal: 1),

        Achievement(id: "breathing.first_breath", category: .breathing, icon: "wind", title: "First Breath", description: "Complete your first breathing exercise.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "breathing.deep_breath", category: .breathing, icon: "lungs.fill", title: "Deep Breath", description: "Do a 5-minute breathing session.", isLocked: true, progress: 0, goal: 5),
        Achievement(id: "breathing.calm_down", category: .breathing, icon: "pause.circle.fill", title: "Calm Down Break", description: "Use a breathing exercise during a stressful moment.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "breathing.focus_session", category: .breathing, icon: "timelapse", title: "Focus Session", description: "Do a focus session before starting work.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "breathing.before_sleep", category: .breathing, icon: "bed.double.circle.fill", title: "Before Sleep", description: "Do a relaxation session before bedtime.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "breathing.streak", category: .breathing, icon: "app.connected.to.app.below.fill", title: "Breathing Streak", description: "Do a breathing exercise 3 days in a row.", isLocked: true, progress: 0, goal: 3),
        Achievement(id: "breathing.total_30_min", category: .breathing, icon: "stopwatch.fill", title: "Total 30 Minutes", description: "Accumulate 30 minutes of breathing exercises.", isLocked: true, progress: 0, goal: 30),
        Achievement(id: "breathing.box_breathing", category: .breathing, icon: "4.square.fill", title: "Box Breathing", description: "Try the box breathing technique.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "breathing.heartbeat", category: .breathing, icon: "heart.fill", title: "Heartbeat", description: "Lower your heartbeat after exercise.", isLocked: true, progress: 0, goal: 1),
        Achievement(id: "breathing.expert", category: .breathing, icon: "crown.fill", title: "Breathing Expert", description: "Complete a total of 25 breathing sessions.", isLocked: true, progress: 0, goal: 25)
    ]
}

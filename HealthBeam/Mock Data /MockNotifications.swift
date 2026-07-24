import SwiftUI
import Foundation
import Combine

// MARK: - Birleştirilmiş Enum
// Eski dosyadaki özellikleri (title, icon, color) buraya taşıdık.
// Yeni dosyadaki case'leri (lowCardioFitness, sleepApnea) koruduk.

enum HeartNotificationType: String, Identifiable, CaseIterable {
    case highHeartRate
    case lowHeartRate
    case irregularRhythm
    case lowCardioFitness // Eskiden 'cardioFitness' idi, güncelledik
    case sleepApnea       // Yeni eklenen (Eskiden hypertension vardı, bunu kullanacağız)

    var id: String { rawValue }

    var title: String {
        switch self {
        case .highHeartRate: return String(localized: "High Heart Rate")
        case .lowHeartRate: return String(localized: "Low Heart Rate")
        case .irregularRhythm: return String(localized: "Irregular Rhythm")
        case .lowCardioFitness: return String(localized: "Low Cardio Fitness")
        case .sleepApnea: return String(localized: "Sleep Apnea")
        }
    }

    var subtitle: String {
        switch self {
        case .highHeartRate: return String(localized: "Episodes during rest")
        case .lowHeartRate: return String(localized: "Very low heart rate events")
        case .irregularRhythm: return String(localized: "Detected irregular rhythms")
        case .lowCardioFitness: return String(localized: "Low cardio fitness alerts")
        case .sleepApnea: return String(localized: "Breathing disturbances detected")
        }
    }

    var icon: String {
        switch self {
        case .highHeartRate: return "arrow.up.heart.fill"
        case .lowHeartRate: return "arrow.down.heart.fill"
        case .irregularRhythm: return "waveform.path.ecg"
        case .lowCardioFitness: return "figure.run.circle.fill"
        case .sleepApnea: return "moon.zzz.fill"
        }
    }

    var color: Color {
        switch self {
        case .highHeartRate: return .red
        case .lowHeartRate: return .blue
        case .irregularRhythm: return .purple
        case .lowCardioFitness: return .teal
        case .sleepApnea: return .indigo
        }
    }
}

// MARK: - Data Models

struct HeartNotificationEntry: Identifiable {
    let id = UUID()
    let type: HeartNotificationType
    let date: Date
    let value: String
    let message: String
}

// MARK: - Mock Data Generator

struct MockNotifications {
    
    static func getMockData(for type: HeartNotificationType) -> HeartNotificationEntry? {
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let lastWeek = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        
        switch type {
        case .highHeartRate:
            return HeartNotificationEntry(
                type: .highHeartRate,
                date: yesterday,
                value: "128 BPM",
                message: "Your heart rate rose above 120 BPM while you appeared to be inactive for 10 minutes."
            )
        case .lowHeartRate:
            return HeartNotificationEntry(
                type: .lowHeartRate,
                date: lastWeek,
                value: "42 BPM",
                message: "Your heart rate fell below 45 BPM for 10 minutes."
            )
        case .irregularRhythm:
            return HeartNotificationEntry(
                type: .irregularRhythm,
                date: Date(),
                value: "Atrial Fibrillation",
                message: "Signs of an irregular rhythm suggestive of atrial fibrillation were identified."
            )
        case .lowCardioFitness:
            return HeartNotificationEntry(
                type: .lowCardioFitness,
                date: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
                value: "Low",
                message: "Your cardio fitness level has been low for the last 4 weeks."
            )
        case .sleepApnea:
            return HeartNotificationEntry(
                type: .sleepApnea,
                date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                value: "Elevated",
                message: "Breathing Disturbances were elevated."
            )
        }
    }
}

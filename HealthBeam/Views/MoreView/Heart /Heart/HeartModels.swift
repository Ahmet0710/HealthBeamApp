import Foundation

enum HeartMetric: String, CaseIterable, Identifiable {
    case heartRate = "Heart Rate"
    case restingHeartRate = "Resting Heart Rate"
    case heartRateVariability = "Heart Rate Variability"
    case walkingHeartRate = "Walking Heart Rate"
    case cardioFitness = "Cardio Fitness"
    case cardioRecovery = "Cardio Recovery"

    var id: String { rawValue }

    var localizedTitle: String {
        String(localized: String.LocalizationValue(rawValue))
    }

    var unit: String {
        switch self {
        case .heartRate,
             .restingHeartRate,
             .walkingHeartRate,
             .cardioRecovery:
            return "bpm"
        case .heartRateVariability:
            return "ms"
        case .cardioFitness:
            return "ml/kg/min"
        }
    }
}

private enum HeartLocalizationCatalog {
    static let strings: [LocalizedStringResource] = [
        "Heart Rate", "Resting Heart Rate", "Heart Rate Variability",
        "Walking Heart Rate", "Cardio Fitness", "Cardio Recovery",
        "Day", "Week", "Month", "Year",
        "Last 6 Months", "All Time",
        "Sinus Rhythm", "Atrial Fibrillation", "Inconclusive (Low HR)",
        "Inconclusive (High HR)", "Inconclusive (Poor Reading)", "Inconclusive",
        "Unrecognized", "Not Set", "Unknown/Other"
    ]
}

struct HeartEntry: Identifiable {
    let id = UUID()
    let metric: HeartMetric
    let value: Double
    let date: Date
}
enum HeartMetricDisplayStyle {
    case timeSeries        // HR, HRV, Cardio Recovery
    case sparseDaily       // Walking HR, Cardio Fitness
    case userEntered       // Peripheral Perfusion
    case pairedSeries      // Blood Pressure (sys/dia)
    case timeline          // AFib History
}

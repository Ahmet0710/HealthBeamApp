import Foundation
enum MeasurementType: String, CaseIterable, Identifiable {
    case weight = "Weight", height = "Height", bodyFatPercentage = "Body Fat %", leanBodyMass = "Lean Body Mass", waistCircumference = "Waist Circumference", bodyMassIndex = "Body Mass Index (BMI)"
    case bodyTemperature = "Body Temperature", basalBodyTemperature = "Basal Body Temperature", wristTemperature = "Wrist Temperature"
    var id: String { self.rawValue }

    var localizedTitle: String {
        String(localized: String.LocalizationValue(rawValue))
    }

    var unit: String {
        switch self {
        case .weight, .leanBodyMass: return "kg"
        case .height, .waistCircumference: return "cm"
        case .bodyFatPercentage: return "%"
        case .bodyTemperature, .basalBodyTemperature, .wristTemperature: return "°C"
        case .bodyMassIndex: return ""
        }
    }
}

private enum MeasurementLocalizationCatalog {
    static let strings: [LocalizedStringResource] = [
        "Weight", "Height", "Body Fat %", "Lean Body Mass", "Waist Circumference",
        "Body Mass Index (BMI)", "Body Temperature", "Basal Body Temperature", "Wrist Temperature",
        "Day", "Week", "Month", "Year"
    ]
}

struct MeasurementEntry: Identifiable {
    let id = UUID()
    let type: MeasurementType
    let value: Double
    let date: Date
}

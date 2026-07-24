import Foundation
import HealthKit

struct ECGEntry: Identifiable {
    let id: UUID
    let date: Date
    let classification: HKElectrocardiogram.Classification
    let averageHeartRate: Double?
    let sample: HKElectrocardiogram?

    var classificationName: String {
        switch classification {
        case .sinusRhythm:
            return String(localized: "Sinus Rhythm")
        case .atrialFibrillation:
            return String(localized: "Atrial Fibrillation")
        case .inconclusiveLowHeartRate:
            return String(localized: "Inconclusive (Low HR)")
        case .inconclusiveHighHeartRate:
            return String(localized: "Inconclusive (High HR)")
        case .inconclusivePoorReading:
            return String(localized: "Inconclusive (Poor Reading)")
        case .inconclusiveOther:
            return String(localized: "Inconclusive")
        case .unrecognized:
            return String(localized: "Unrecognized")
        case .notSet:
            return String(localized: "Not Set")
        @unknown default:
            return String(localized: "Unknown/Other")
        }
    }
}

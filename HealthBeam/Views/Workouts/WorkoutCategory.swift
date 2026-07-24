import Foundation
import HealthKit
enum WorkoutCategory: String, Codable, CaseIterable, Hashable, Identifiable {
    case cardio
    case strength
    case flexibility
    case balance
    case recovery
    case other
    var id: String { rawValue }
    var hkType: HKWorkoutActivityType {
        switch self {
            case .cardio: return .running
            case .strength: return .traditionalStrengthTraining
            case .flexibility: return .yoga
            case .balance: return .taiChi
            case .recovery: return .mindAndBody
            case .other: return .other
        }
    }
}

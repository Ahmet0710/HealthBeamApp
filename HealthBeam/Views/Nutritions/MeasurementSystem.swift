import Foundation
enum MeasurementSystem: String, CaseIterable, Hashable {
    case Metric
    case Imperial
    var title: String {
        switch self {
        case .Metric: return String(localized: "Metric")
        case .Imperial: return String(localized: "Imperial")
        }
    }
}
extension MeasurementSystem: PremiumPickable {}
extension MeasurementSystem {
    func formatEnergy(_ kilocalories: Double) -> String {
        String(format: "%.0f kcal", kilocalories)
    }
    func formatWater(_ liters: Double) -> String {
        switch self {
        case .Metric:
            if liters >= 1.0 {
                return String(format: "%.2f L", liters)
            } else {
                return String(format: "%.0f mL", liters * 1000.0)
            }
        case .Imperial:
            let ounces = liters * 33.814
            return String(format: "%.0f oz", ounces)
        }
    }

    func formatWeight(_ kilograms: Double) -> String {
        switch self {
        case .Metric:
            return String(format: "%.1f kg", kilograms)
        case .Imperial:
            let pounds = kilograms * 2.20462
            return String(format: "%.1f lb", pounds)
        }
    }

    func formatHeight(_ centimeters: Double) -> String {
        switch self {
        case .Metric:
            return String(format: "%.0f cm", centimeters)
        case .Imperial:
            let totalInches = centimeters * 0.3937007874
            let feet = Int(totalInches / 12.0)
            let inches = Int(round(totalInches - Double(feet) * 12.0))
            return "\(feet)′ \(inches)″"
        }
    }
}

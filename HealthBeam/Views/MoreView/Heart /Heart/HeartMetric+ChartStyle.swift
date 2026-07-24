import SwiftUI
extension HeartMetric {

    enum HeartChartStyle {
        case continuous   // Line + Area
        case discrete     // Point
    }
    
    var chartStyle: HeartChartStyle {
        switch self {

        // Sürekli zaman serileri
        case .heartRate,
             .restingHeartRate,
             .heartRateVariability,
             .cardioRecovery:
            return .continuous

        // Seyrek / günde 1 / kullanıcı girişi
        case .walkingHeartRate,
             .cardioFitness:
            return .discrete
        }
    }
}

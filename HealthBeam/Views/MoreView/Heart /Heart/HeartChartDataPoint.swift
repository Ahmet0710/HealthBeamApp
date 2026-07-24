import Foundation

struct HeartChartDataPoint: Identifiable, Equatable {

    let date: Date

    /// Grafiklerde kullanılan ana değer (Chart y ekseni)
    let value: Double

    /// Metric detayları
    let HeartRate: Double
    let lowestHeartRateBPM: Double
    let maximumHeartRateBPM: Double
    let restingHeartRateBPM: Double

    let hrv: Double
    let respiratoryRate: Double

    let activeCaloriesBurned: Double
    let workoutDurationMinutes: Double
    let workoutType: String

    var id: Date { date }
}

extension HeartChartDataPoint {

    /// Average Heart Rate için kullanılan sade initializer
    init(
        date: Date,
        HeartRate: Double
    ) {
        self.init(
            date: date,
            value: HeartRate,
            HeartRate: HeartRate,
            lowestHeartRateBPM: HeartRate,
            maximumHeartRateBPM: HeartRate,
            restingHeartRateBPM: HeartRate,
            hrv: 0,
            respiratoryRate: 0,
            activeCaloriesBurned: 0,
            workoutDurationMinutes: 0,
            workoutType: ""
        )
    }
}

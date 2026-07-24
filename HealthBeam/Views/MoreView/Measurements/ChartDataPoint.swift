import Foundation
struct ChartDataPoint: Identifiable, Equatable{
    let date: Date
    let value: Double

    let totalSleepDurationMinutes: Double
    let timeInBedMinutes: Double
    let lightSleepDurationMinutes: Double

    var id: Date { date }
}

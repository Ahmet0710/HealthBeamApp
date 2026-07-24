import Foundation
struct HeartRateEvent: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let averageBPM: Double // Eğer veri yoksa 0 dönecek
    let kind: Kind

    enum Kind {
        case high
        case low
        case irregular
        case lowCardio
        case sleepApnea
    }
}

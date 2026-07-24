import Foundation

struct ECGPoint: Identifiable {
    let id = UUID()
    let time: Double
    let voltage: Double
}

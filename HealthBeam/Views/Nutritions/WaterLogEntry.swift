import Foundation
struct WaterLogEntry: Identifiable, Equatable {
    let id: UUID
    let amountLiters: Double
    let date: Date
}

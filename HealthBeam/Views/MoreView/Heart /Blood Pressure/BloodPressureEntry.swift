import Foundation

struct BloodPressureEntry: Identifiable {
    let id: UUID
    let date: Date
    let systolic: Double
    let diastolic: Double
}

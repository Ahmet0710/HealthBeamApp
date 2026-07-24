import SwiftUI
import Combine
class MeasurementSystemManager: ObservableObject {
    var objectWillChange: ObservableObjectPublisher
    @AppStorage("measurementSystem") var measurementSystemRawValue: String = MeasurementSystem.Metric.rawValue {
        didSet {
            objectWillChange.send()
        }
    }
    init() {
        objectWillChange = ObservableObjectPublisher()
    }
    var measurementSystem: MeasurementSystem {
        MeasurementSystem(rawValue: measurementSystemRawValue) ?? .Metric
    }
    func setSystem(_ system: MeasurementSystem) {
        measurementSystemRawValue = system.rawValue
    }
}

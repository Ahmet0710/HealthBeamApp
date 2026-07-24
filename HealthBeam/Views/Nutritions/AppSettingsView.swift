import SwiftUI

struct SettingsUnitsView: View {
    @EnvironmentObject private var measurementSystemManager: MeasurementSystemManager
    var body: some View {
        Form {
            Section(header: Text("Units")) {
                Picker("Measurement System", selection: bindingForSystem) {
                    Text("Metric").tag(MeasurementSystem.Metric)
                    Text("Imperial").tag(MeasurementSystem.Imperial)
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("Settings")
    }
    private var bindingForSystem: Binding<MeasurementSystem> {
        Binding<MeasurementSystem>(
            get: { measurementSystemManager.measurementSystem },
            set: { measurementSystemManager.setSystem($0) }
        )
    }
}

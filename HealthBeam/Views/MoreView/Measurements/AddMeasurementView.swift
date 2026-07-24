import SwiftUI
struct AddMeasurementView: View {
    @State private var selectedType: MeasurementType = .weight
    @State private var valueString: String = ""
    @State private var selectedDate: Date = Date()

    @Environment(\.dismiss) var dismiss
    var onSave: (MeasurementEntry) -> Void

    private var isSaveDisabled: Bool { Double(valueString) == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Measurement Details")) {
                    Picker("Measurement Type", selection: $selectedType) {
                        ForEach(MeasurementType.allCases.filter { $0 != .wristTemperature }, id: \.self) { type in
                            Text(type.localizedTitle).tag(type)
                        }
                    }
                    HStack {
                        TextField("Value", text: $valueString).keyboardType(.decimalPad)
                        Spacer()
                        Text(selectedType.unit).foregroundColor(.secondary)
                    }
                }
                Section(header: Text("Date & Time")) {
                    DatePicker("Date", selection: $selectedDate)
                        .tint(.white) // ✅ Date Picker oklarını ve seçiciyi Beyaz yapar
                }
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.white) // ✅ Tüm butonları (Save/Cancel) Beyaz yapar
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveMeasurement() }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .disabled(isSaveDisabled)
                }
            }
        }
    }

    private func saveMeasurement() {
        guard let value = Double(valueString) else { return }
        let newEntry = MeasurementEntry(type: selectedType, value: value, date: selectedDate)
        Task {
            try? await HealthKitManager.shared.saveMeasurement(newEntry)
            onSave(newEntry)
            dismiss()
        }
    }
}

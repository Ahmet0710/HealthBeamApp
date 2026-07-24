import SwiftUI
import HealthKit

private enum HeartMeasurementType: String, CaseIterable, Identifiable {
    case heartRate = "Heart Rate"
    case restingHeartRate = "Resting Heart Rate"
    case heartRateVariability = "Heart Rate Variability (HRV)"
    var id: Self { self }

    var localizedTitle: String {
        String(localized: String.LocalizationValue(rawValue))
    }
    var unit: String {
        switch self {
            case .heartRate, .restingHeartRate: return "bpm"
            case .heartRateVariability: return "ms"
        }
    }
    var displayName: String { localizedTitle }
}
struct AddHeartView: View {
    @State private var selectedType: HeartMeasurementType = .heartRate
    @State private var valueString: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false

    @Environment(\.dismiss) var dismiss
    var onSave: (() -> Void)? = nil

    private var isSaveDisabled: Bool {
        guard let v = Double(valueString) else { return true }
        return v <= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Heart Data Type")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(HeartMeasurementType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    HStack {
                        TextField("Value", text: $valueString).keyboardType(.decimalPad)
                        Text(selectedType.unit).foregroundStyle(.secondary)
                    }
                }

                Section(header: Text("Date & Time")) {
                    Button {
                        withAnimation(.snappy) { showDatePicker.toggle() }
                    } label: {
                        HStack {
                            Text("Date").foregroundStyle(.primary)
                            Spacer()
                            Text(selectedDate.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(showDatePicker ? .white : .secondary) // ✅ Seçili tarih vurgusu Beyaz
                        }
                    }
                    
                    if showDatePicker {
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .tint(.white) // ✅ Takvim okları ve gün seçimi Beyaz yapıldı
                    }
                }
            }
            .navigationTitle("Add Data")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.white)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveData() }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .disabled(isSaveDisabled)
                }
            }
        }
    }

    private func saveData() {
        guard let value = Double(valueString) else { return }
        Task {
            do {
                let identifier: HKQuantityTypeIdentifier
                let unit: HKUnit
                switch selectedType {
                case .heartRate: identifier = .heartRate; unit = HKUnit.count().unitDivided(by: .minute())
                case .restingHeartRate: identifier = .restingHeartRate; unit = HKUnit.count().unitDivided(by: .minute())
                case .heartRateVariability: identifier = .heartRateVariabilitySDNN; unit = HKUnit.init(from: "ms")
                }
                if let type = HKQuantityType.quantityType(forIdentifier: identifier) {
                    let quantity = HKQuantity(unit: unit, doubleValue: value)
                    let sample = HKQuantitySample(type: type, quantity: quantity, start: selectedDate, end: selectedDate)
                    try await HealthKitManager.shared.healthStore.save(sample)
                }
                onSave?()
                dismiss()
            } catch { print("Error saving: \(error)") }
        }
    }
}

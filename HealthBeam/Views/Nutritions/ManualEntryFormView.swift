import SwiftUI
struct ManualEntryFormView: View {
    @Binding var foodName: String
    @Binding var calories: Double
    @Binding var protein: Double
    @Binding var carbs: Double
    @Binding var fat: Double
    @Binding var sugar: Double
    @Binding var selectedMealType: MealType

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enter Food Details")
                .font(.headline)
                .foregroundColor(.primary)
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Food Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("e.g., Grilled Chicken", text: $foodName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(.tertiarySystemBackground).opacity(0.7))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal Type")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Meal Type", selection: $selectedMealType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.rawValue.capitalized)
                                .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .background(Color(.tertiarySystemBackground).opacity(0.7))
                    .cornerRadius(8)
                }

                VStack(spacing: 12) {
                    MacronutrientInputView(
                        title: "Calories",
                        value: $calories,
                        unit: "kcal",
                        color: .orange
                    )

                    MacronutrientInputView(
                        title: "Protein",
                        value: $protein,
                        unit: "g",
                        color: .blue
                    )

                    MacronutrientInputView(
                        title: "Carbs",
                        value: $carbs,
                        unit: "g",
                        color: .green
                    )

                    MacronutrientInputView(
                        title: "Fat",
                        value: $fat,
                        unit: "g",
                        color: .yellow
                    )

                    MacronutrientInputView(
                        title: "Sugar",
                        value: $sugar,
                        unit: "g",
                        color: .pink
                    )
                }
                .padding(.vertical, 8)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground).opacity(0.7))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, 4)
    }
}

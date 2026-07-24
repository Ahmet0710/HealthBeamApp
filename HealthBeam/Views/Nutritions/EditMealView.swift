import SwiftUI
import SwiftData

struct EditMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var meal: Meal
    @State private var showDeleteConfirmation = false

    private var isFormValid: Bool {
        !meal.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && meal.calories > 0
    }

    private var mealTypeTint: Color {
        switch meal.mealType {
        case .breakfast:
            return .orange
        case .lunch:
            return .green
        case .dinner:
            return .indigo
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    mealTypeTint.opacity(0.22),
                    Color.black,
                    Color(red: 0.07, green: 0.08, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    topBar
                    summaryCard
                    detailsCard
                    nutritionCard
                    deleteCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Delete Meal", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(meal)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this meal? This action cannot be undone.")
        }
    }

    private var topBar: some View {
        HStack {
            Button("İptal") {
                dismiss()
            }
            .buttonStyle(EditorCapsuleButtonStyle(background: Color.white.opacity(0.06), foreground: .white.opacity(0.86)))

            Spacer()

            Text("Yemeği Düzenle")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)

            Spacer()

            Button("Kaydet") {
                dismiss()
            }
            .buttonStyle(EditorCapsuleButtonStyle(background: isFormValid ? mealTypeTint.opacity(0.22) : Color.white.opacity(0.04), foreground: isFormValid ? .white : .white.opacity(0.4)))
            .disabled(!isFormValid)
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(mealTypeTint.opacity(0.16))
                .frame(width: 58, height: 58)
                .overlay(
                    Image(systemName: meal.mealType.systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(mealTypeTint)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(meal.name.isEmpty ? "Unnamed Meal" : meal.name)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    editorInfoPill(meal.mealType.rawValue, tint: mealTypeTint)
                    editorInfoPill(meal.time.formatted(date: .abbreviated, time: .shortened), tint: .white.opacity(0.7))
                }
            }

            Spacer()
        }
        .padding(18)
        .background(editorCardBackground)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("Meal Details")

            editorField(title: "Meal name") {
                TextField("Chicken Bowl", text: $meal.name)
                    .textInputAutocapitalization(.words)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Meal Type")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))

                Picker("Meal Type", selection: $meal.mealType) {
                    ForEach(MealType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Time")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 12) {
                    DatePicker("", selection: $meal.time, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)

                    DatePicker("", selection: $meal.time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                }
            }
        }
        .padding(18)
        .background(editorCardBackground)
    }

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Nutrition")

            nutritionRow(title: "Calories", unit: "kcal", value: $meal.calories, tint: .orange)
            nutritionRow(title: "Protein", unit: "g", value: $meal.protein, tint: .pink)
            nutritionRow(title: "Carbs", unit: "g", value: $meal.carbs, tint: .teal)
            nutritionRow(title: "Fat", unit: "g", value: $meal.fat, tint: .yellow)
            nutritionRow(title: "Sugar", unit: "g", value: $meal.sugar, tint: .mint)
        }
        .padding(18)
        .background(editorCardBackground)
    }

    private var deleteCard: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .semibold))
                Text("Delete Meal")
                    .font(.headline.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(.red)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.red.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.red.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(.white.opacity(0.92))
    }

    private func editorField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
        }
    }

    private func nutritionRow(title: String, unit: String, value: Binding<Double>, tint: Color) -> some View {
        HStack {
            HStack(spacing: 10) {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 12, height: 12)
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
            }

            Spacer()

            TextField("0", value: value, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.white)
                .frame(width: 80)

            Text(unit)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 40, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    private func editorInfoPill(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(tint.opacity(0.12))
            )
    }

    private var editorCardBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct EditorCapsuleButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(background.opacity(configuration.isPressed ? 0.75 : 1))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

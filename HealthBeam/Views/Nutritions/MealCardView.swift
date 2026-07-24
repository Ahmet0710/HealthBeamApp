import SwiftUI

struct MealCardView: View {
    let meal: Meal
    var onDelete: (() -> Void)?
    var onShare: (() -> Void)?
    var onEdit: (() -> Void)?

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

    private var mealTypeLabel: String {
        meal.mealType.rawValue
    }

    private var timeLabel: String {
        meal.time.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            headerRow
            macroRow
            actionRow
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(mealTypeTint.opacity(0.16))
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: meal.mealType.systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(mealTypeTint)
                )

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(meal.name)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Spacer(minLength: 12)
                    Text("\(Int(meal.calories)) kcal")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                HStack(spacing: 8) {
                    mealInfoPill(title: mealTypeLabel, foreground: mealTypeTint, background: mealTypeTint.opacity(0.14))
                    mealInfoPill(title: timeLabel, foreground: .white.opacity(0.72), background: Color.white.opacity(0.06))
                }
            }
        }
    }

    private var macroRow: some View {
        HStack(spacing: 10) {
            MacroTile(title: "Protein", value: meal.protein, tint: .pink)
            MacroTile(title: "Carbs", value: meal.carbs, tint: .teal)
            MacroTile(title: "Fat", value: meal.fat, tint: .orange)
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        HStack(spacing: 10) {
            if let onEdit {
                ActionChip(title: "Edit", systemImage: "pencil", tint: .green, action: onEdit)
            }

            if let onShare {
                ActionChip(title: "Share", systemImage: "square.and.arrow.up", tint: .mint, action: onShare)
            }

            Spacer(minLength: 0)

            if let onDelete {
                ActionChip(title: "Delete", systemImage: "trash", tint: .red, action: onDelete, role: .destructive)
            }
        }
        .padding(.top, 2)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
    }

    private func mealInfoPill(title: String, foreground: Color, background: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(background)
            )
    }
}

private struct MacroTile: View {
    let title: String
    let value: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
            Text("\(Int(value))g")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

private struct ActionChip: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void
    var role: ButtonRole?

    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(tint.opacity(0.12))
                        .overlay(
                            Capsule()
                                .stroke(tint.opacity(0.22), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

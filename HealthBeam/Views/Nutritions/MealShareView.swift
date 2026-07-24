import SwiftUI

struct MealShareView: View {
    let meal: Meal

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
                    mealTypeTint.opacity(0.34),
                    Color.black,
                    Color(red: 0.05, green: 0.08, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HealthBeam")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("Today's Meal")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Fuel logged with intention.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(mealTypeTint.opacity(0.18))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: meal.mealType.systemImage)
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(mealTypeTint)
                        )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(meal.name)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 10) {
                        sharePill(meal.mealType.rawValue, tint: mealTypeTint)
                        sharePill(meal.time.formatted(date: .abbreviated, time: .shortened), tint: .white.opacity(0.7))
                    }
                }

                HStack(spacing: 12) {
                    shareStatCard(title: "Calories", value: "\(Int(meal.calories))", unit: "kcal", tint: .orange)
                    shareStatCard(title: "Protein", value: "\(Int(meal.protein))", unit: "g", tint: .pink)
                }

                HStack(spacing: 12) {
                    shareStatCard(title: "Carbs", value: "\(Int(meal.carbs))", unit: "g", tint: .teal)
                    shareStatCard(title: "Fat", value: "\(Int(meal.fat))", unit: "g", tint: .yellow)
                }

                if meal.sugar > 0 {
                    HStack {
                        Text("Sugar")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                        Spacer()
                        Text("\(Int(meal.sugar)) g")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                }
            }
            .padding(28)
        }
        .frame(width: 1080, height: 1350)
    }

    private func sharePill(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tint.opacity(0.14))
            )
    }

    private func shareStatCard(title: String, value: String, unit: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

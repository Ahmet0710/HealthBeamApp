import SwiftUI
import HealthKit

struct WaterTrackerView: View {
    @EnvironmentObject var viewModel: NutritionViewModel
    @EnvironmentObject private var measurementSystemManager: MeasurementSystemManager

    @State private var selectedQuickAdd: Double = 0.5

    private let quickAddAmounts: [Double] = [0.25, 0.5, 0.75, 1.0]

    private var progress: Double {
        guard viewModel.dailyWaterGoalLiters > 0 else { return 0 }
        return min(viewModel.todayWaterIntakeLiters / viewModel.dailyWaterGoalLiters, 1.0)
    }

    private var remainingLiters: Double {
        max(viewModel.dailyWaterGoalLiters - viewModel.todayWaterIntakeLiters, 0)
    }

    private var progressPercent: Int {
        Int((progress * 100).rounded())
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    heroCard
                    quickAddCard
                    recentLogsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Water tracking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .foregroundStyle(.white)
        .onAppear {
            Task {
                await viewModel.fetchRecentWaterLogs()
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.07, blue: 0.17),
                    Color(red: 0.03, green: 0.04, blue: 0.10),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.18))
                .blur(radius: 85)
                .frame(width: 280, height: 280)
                .offset(x: 120, y: -250)

            Circle()
                .fill(Color.blue.opacity(0.16))
                .blur(radius: 110)
                .frame(width: 320, height: 320)
                .offset(x: -120, y: 180)
        }
    }

    private var heroCard: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hydration")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(progress >= 1 ? "You reached your goal today." : "\(measurementSystemManager.measurementSystem.formatWater(remainingLiters)) left to hit your target.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                statusPill
            }

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 24)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.cyan.opacity(0.95),
                                Color.blue,
                                Color.teal,
                                Color.cyan.opacity(0.95)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.7, dampingFraction: 0.82), value: progress)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 90
                        )
                    )
                    .padding(30)

                VStack(spacing: 6) {
                    Text(measurementSystemManager.measurementSystem.formatWater(viewModel.todayWaterIntakeLiters))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Goal \(measurementSystemManager.measurementSystem.formatWater(viewModel.dailyWaterGoalLiters))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.66))
                    Text("\(progressPercent)% complete")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.cyan.opacity(0.92))
                }
            }
            .frame(width: 250, height: 250)

            progressFooter
        }
        .padding(22)
        .background(cardBackground(tint: Color.cyan))
    }

    private var statusPill: some View {
        Text(progress >= 1 ? "On target" : "Keep going")
            .font(.caption.weight(.bold))
            .foregroundStyle(progress >= 1 ? Color.green : Color.cyan)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }

    private var progressFooter: some View {
        HStack(spacing: 12) {
            metricTile(
                title: "Consumed",
                value: measurementSystemManager.measurementSystem.formatWater(viewModel.todayWaterIntakeLiters),
                tint: .cyan
            )

            metricTile(
                title: "Remaining",
                value: measurementSystemManager.measurementSystem.formatWater(remainingLiters),
                tint: .blue
            )
        }
    }

    private func metricTile(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var quickAddCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Add")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Choose an amount, then add it with one tap.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.66))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(quickAddAmounts, id: \.self) { amount in
                    quickAddOption(for: amount)
                }
            }

            Button {
                Task { await viewModel.logWater(liters: selectedQuickAdd) }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3.weight(.bold))
                    Text("Add \(measurementSystemManager.measurementSystem.formatWater(selectedQuickAdd))")
                        .font(.headline.weight(.bold))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color.cyan.opacity(0.25), radius: 16, x: 0, y: 10)
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .background(cardBackground(tint: Color.blue))
    }

    private func quickAddOption(for amount: Double) -> some View {
        let isSelected = selectedQuickAdd == amount

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                selectedQuickAdd = amount
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: isSelected ? "drop.fill" : "drop")
                        .font(.headline.weight(.bold))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.headline)
                    }
                }
                .foregroundStyle(isSelected ? .white : .white.opacity(0.72))

                Text(measurementSystemManager.measurementSystem.formatWater(amount))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(quickAddLabel(for: amount))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Color.cyan.opacity(0.26) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected ? Color.cyan.opacity(0.55) : Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func quickAddLabel(for amount: Double) -> String {
        switch amount {
        case 0.25: return "Small sip"
        case 0.5: return "Standard glass"
        case 0.75: return "Large glass"
        default: return "Big bottle"
        }
    }

    private var recentLogsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Activity")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Your latest water logs for today.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.66))
                }
                Spacer()
            }

            if viewModel.recentWaterLogs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "drop.circle")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(.cyan.opacity(0.85))
                    Text("No water logged yet")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Use the quick add options above to record your first glass.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.62))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(viewModel.recentWaterLogs.enumerated()), id: \.element.id) { index, log in
                        waterLogRow(log: log, index: index)
                    }
                }
            }
        }
        .padding(22)
        .background(cardBackground(tint: Color.white))
    }

    private func waterLogRow(log: WaterLogEntry, index: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.14))
                    .frame(width: 46, height: 46)
                Image(systemName: "drop.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.cyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(measurementSystemManager.measurementSystem.formatWater(log.amountLiters))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(timeFormatter.string(from: log.date))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            Button {
                Task {
                    await viewModel.deleteWaterLog(logToDelete: log)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(index == 0 ? 0.08 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func cardBackground(tint: Color) -> some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(tint.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

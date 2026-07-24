// Dosya: GoalSettingsView.swift

import SwiftUI

struct GoalSettingsView: View {
    @ObservedObject var viewModel: ProgressViewModel

    var body: some View {
        Form {
            Section(header: Text("Daily Target")) {
                Stepper(
                    "\(viewModel.dailyGoalInMinutes) Minutes",
                    value: $viewModel.dailyGoalInMinutes,
                    in: 5...120,
                    step: 5
                )
            }

            Section(header: Text("Weekly Target")) {
                Stepper(
                    "\(viewModel.weeklyGoalTarget) Day",
                    value: $viewModel.weeklyGoalTarget,
                    in: 1...7,
                    step: 1
                )
            }

            Section(header: Text("Monthly Target")) {
                Stepper(
                    "\(viewModel.monthlyGoalTarget) Day",
                    value: $viewModel.monthlyGoalTarget,
                    in: 1...31,
                    step: 1
                )
            }
        }
        .navigationTitle("Set the targets")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.dailyGoalInMinutes) { _, newValue in
            viewModel.updateDailyGoal(newGoal: newValue)
        }
        .onChange(of: viewModel.weeklyGoalTarget) { _, newValue in
            viewModel.updateWeeklyGoal(newGoal: newValue)
        }
        .onChange(of: viewModel.monthlyGoalTarget) { _, newValue in
            viewModel.updateMonthlyGoal(newGoal: newValue)
        }
    }
}

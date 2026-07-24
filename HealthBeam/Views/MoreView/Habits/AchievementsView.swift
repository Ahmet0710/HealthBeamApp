import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var viewModel: HabitsViewModel
    var body: some View {
        NavigationStack {
            List(viewModel.badges) { badge in
                HStack {
                    Image(systemName: badge.icon)
                        .foregroundColor(badge.unlocked ? .yellow : .gray)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text(badge.localizedName)
                            .fontWeight(.semibold)
                        Text(badge.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if badge.unlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Achievements")
        }
        .onAppear {
            viewModel.refreshBadges()
        }
    }
}

import SwiftUI

struct MindfulnessHomeView: View {
    @Environment(\.dismiss) private var dismiss
    
    private enum Tab {
        case discover, history, progress, Downloads
    }

    @State private var selectedTab: Tab = .discover
    private var navigationTitle: String {
        switch selectedTab {
        case .discover:
            return "Discover"
        case .history:
            return "History"
        case .progress:
            return "Progress"
        case .Downloads:
            return "Downloads"
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MindfulnessSectionView()
                .tabItem { Label("Discover", systemImage: "safari.fill") }
                .tag(Tab.discover)
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(Tab.history)
            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.pie.fill") }
                .tag(Tab.progress)
            DownloadsManagementView()
                .tabItem { Label("Downloads", systemImage: "arrow.down.circle.fill") }
                .tag(Tab.Downloads)
            
            
            
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                switch selectedTab {
                case .discover:
                    NavigationLink(destination: FavoritesView()) {
                        Image(systemName: "heart.fill")
                    }
                case .progress:
                    NavigationLink(destination: GoalSettingsView(viewModel: ProgressViewModel())) {
                        Image(systemName: "gearshape.fill")
                    }
                case .Downloads:
                    EmptyView()
                case .history:
                    EmptyView()
                
                }
            }
        }
        .tint(tintColor(for: selectedTab))
    }
    
    private func tintColor(for tab: Tab) -> Color {
        switch tab {
        case .discover, .history,.Downloads:
            return .green
        case .progress:
            return .gray
        }
    }
}

#Preview {
    NavigationStack {
        MindfulnessHomeView()
            .preferredColorScheme(.dark)
    }
}

import SwiftUI
import Charts

struct ProgressDashboardView: View {
    // Manages statistics data via ViewModel
    @StateObject private var viewModel = ProgressViewModel()

    var body: some View {
        ZStack {
            // Background Design
            Color.black.ignoresSafeArea()
            LinearGradient(colors: [.gray.opacity(0.5), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    
                    // 1. Daily Goal Ring
                    dailyGoalSection()
                    
                    // 2. Weekly Activity Chart
                    weeklyActivitySection()
                   
                    // 4. Goal Cards (Weekly/Monthly)
                    goalsSection()
                    
                    // 5. General Statistics
                    statisticsSection()
                }
                .padding(.vertical)
            }
        }
        .onAppear {
            // Refresh data on every appear
            viewModel.loadGoals()
            viewModel.calculateAllStats()
        }
    }

    // MARK: - Sections

    // Storage Management Card
    private func downloadsManagementSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage & Downloads")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
                .foregroundColor(.white)
            
            NavigationLink(destination: DownloadsManagementView()) {
                HStack {
                    Image(systemName: "folder.fill.badge.gearshape")
                        .font(.title2)
                        .frame(width: 45, height: 45)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Downloaded Meditations")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Manage files and free up space")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)))
                .padding(.horizontal)
            }
        }
    }

    private func dailyGoalSection() -> some View {
        VStack(alignment: .leading) {
            Text("Today's Goal").font(.title2).fontWeight(.bold)
                .padding(.horizontal).foregroundColor(.white)
            DailyGoalRingView(
                progress: viewModel.goalProgress,
                todayMinutes: viewModel.todayMinutes,
                goalMinutes: viewModel.dailyGoalInMinutes
            )
            .padding(.horizontal)
        }
    }

    private func weeklyActivitySection() -> some View {
        VStack(alignment: .leading) {
            Text("Weekly Activity").font(.title2).fontWeight(.bold)
                .padding(.horizontal).foregroundColor(.white)
            Chart(viewModel.weeklyData) { dataPoint in
                BarMark(x: .value("Day", dataPoint.date, unit: .day), y: .value("Minutes", dataPoint.minutes))
                    .foregroundStyle(Color.cyan.gradient).cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)); AxisTick()
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true).foregroundStyle(.white.opacity(0.7))
                }
            }
            .chartYAxis(.hidden).frame(height: 180).padding([.horizontal, .top])
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
            .padding(.horizontal)
        }
    }

    private func goalsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Target Goals").font(.title2).fontWeight(.bold).padding(.horizontal).foregroundColor(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ProgressGoalCardView(title: "Weekly Target", progress: viewModel.weeklyGoalProgress, target: viewModel.weeklyGoalTarget, color: .green)
                ProgressGoalCardView(title: "Monthly Target", progress: viewModel.monthlyGoalProgress, target: viewModel.monthlyGoalTarget, color: .purple)
            }.padding(.horizontal)
        }
    }

    private func statisticsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics").font(.title2).fontWeight(.bold).padding(.horizontal).foregroundColor(.white)
            StatisticCardView(icon: "flame.fill", title: "Current Streak", value: "\(viewModel.currentStreak) Days", color: .orange)
            StatisticCardView(icon: "crown.fill", title: "Best Streak", value: "\(viewModel.longestStreak) Days", color: .yellow)
            NavigationLink(destination: HistoryView()) {
                StatisticCardView(icon: "list.bullet.clipboard.fill", title: "Total Sessions", value: "\(viewModel.totalSessions)", color: .indigo)
            }.buttonStyle(.plain)
            StatisticCardView(icon: "clock.fill", title: "Total Time", value: "\(viewModel.totalMinutes) min", color: .blue)
        }.padding(.horizontal)
    }
}

// MARK: - Subviews

struct DailyGoalRingView: View {
    let progress: Double; let todayMinutes: Int; let goalMinutes: Int
    var body: some View {
        ZStack {
            Circle().stroke(lineWidth: 15).opacity(0.1).foregroundColor(.gray)
            Circle().trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                .foregroundColor(.cyan).rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
            VStack {
                Text("\(todayMinutes) / \(goalMinutes)").font(.title).bold()
                Text("minutes").font(.caption).foregroundStyle(.secondary)
            }.foregroundColor(.white)
        }.frame(height: 150).padding()
    }
}

struct ProgressGoalCardView: View {
    let title: String; let progress: Int; let target: Int; let color: Color
    private var progressRatio: Double { target > 0 ? min(1.0, Double(progress) / Double(target)) : 0 }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundColor(.white.opacity(0.8))
            Text("\(progress) / \(target) Days").font(.title2).fontWeight(.bold).foregroundColor(.white)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.2)).frame(height: 8)
                    Capsule().fill(color).frame(width: geo.size.width * progressRatio, height: 8)
                        .animation(.easeInOut, value: progressRatio)
                }
            }
        }.padding().background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)))
    }
}

struct StatisticCardView: View {
    let icon: String; let title: String; let value: String; let color: Color
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title2).frame(width: 45, height: 45)
                .background(color.opacity(0.2)).foregroundColor(color).clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.white.opacity(0.7))
                Text(value).font(.headline).fontWeight(.bold).foregroundColor(.white)
            }
            Spacer()
        }.padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)))
    }
}

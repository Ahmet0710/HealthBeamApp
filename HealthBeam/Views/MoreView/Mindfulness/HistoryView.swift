import SwiftUI

struct HistoryView: View {
    @State private var groupedSessions: [Date: [CompletedSession]] = [:]
    @State private var sortedDates: [Date] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LinearGradient(colors: [.green.opacity(0.2), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    if sortedDates.isEmpty {
                        emptyStateView()
                    } else {
                        ForEach(sortedDates, id: \.self) { date in
                            VStack(alignment: .leading, spacing: 15) {
                                Text(formatDateHeader(date))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .textCase(.uppercase)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                ForEach(groupedSessions[date] ?? []) { session in
                                    HistoryCard(session: session)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.top)
            }
        }
        .onAppear { loadAndGroupSessions() }
    }

    private func loadAndGroupSessions() {
        let allSessions = HistoryManager.shared.loadSessions()
        groupedSessions = Dictionary(grouping: allSessions) { session in
            Calendar.current.startOfDay(for: session.completionDate)
        }
        sortedDates = groupedSessions.keys.sorted(by: >)
    }

    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Spacer(minLength: 100)
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            Text("No history yet.")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HistoryCard: View {
    let session: CompletedSession
    private var meditation: Meditation? { allMeditations.first { $0.id == session.meditationID } }

    private var categoryColor: Color {
        guard let category = meditation?.categoryName else { return .green }
        // Case-sensitive hataları önlemek için tam kontrol
        switch category {
        case "Relaxing Sleep": return Color(red: 0.1, green: 0.1, blue: 0.7)
        case "Self-Worth and Love": return Color(red: 1.0, green: 0.7, blue: 0.8)
        case "Relationships and Connection": return .orange
        case "Inner Peace and Calmness": return Color(red: 0.0, green: 0.8, blue: 0.8)
        case "Growth and Transformation": return Color(red: 0.4, green: 0.8, blue: 0.6)
        case "Energy and Focus": return .black
        default: return .green
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(categoryColor.opacity(0.2)).frame(width: 48, height: 48)
                Image(systemName: "sparkles")
                    .foregroundColor(categoryColor == .black ? .white : categoryColor)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meditation?.title ?? "Unknown Session")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Label("\(meditation?.durationInMinutes ?? 0) min", systemImage: "clock")
                    Text("•")
                    Text(session.completionDate, style: .time)
                }
                .font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(categoryColor == .black ? .white.opacity(0.5) : categoryColor.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(categoryColor.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(categoryColor.opacity(0.2), lineWidth: 1))
        )
    }
}

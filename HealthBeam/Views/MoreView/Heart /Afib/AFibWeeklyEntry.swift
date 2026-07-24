import Foundation

struct AFibWeeklyEntry: Identifiable {
    let id = UUID()
    let weekStart: Date
    let weekEnd: Date
    let percentage: Double
}

extension AFibWeeklyEntry {

    var displayPercentage: Double {
        max(percentage, 2)
    }

    var displayPercentageText: String {
        percentage < 2 ? "<2%" : "\(Int(percentage))%"
    }

    var weekRangeText: String {
        let start = weekStart.formatted(.dateTime.day().month())
        let end = weekEnd.addingTimeInterval(-1)
            .formatted(.dateTime.day().month().year())
        return "\(start) – \(end)"
    }
}

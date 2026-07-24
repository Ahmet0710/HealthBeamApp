import Foundation

struct BloodPressurePoint: Identifiable {
    let id = UUID()
    let date: Date
    let systolic: Double
    let diastolic: Double
}
extension Array where Element == BloodPressureEntry {

    private var calendar: Calendar { .current }

    // DAY → tüm ölçümler
    func forDay(_ date: Date) -> [BloodPressurePoint] {
        let interval = calendar.dateInterval(of: .day, for: date)!
        return self
            .filter { interval.contains($0.date) }
            .sorted { $0.date < $1.date }
            .map {
                BloodPressurePoint(
                    date: $0.date,
                    systolic: $0.systolic,
                    diastolic: $0.diastolic
                )
            }
    }

    // WEEK / MONTH → her günün SON ölçümü
    private func lastPerDay(
        component: Calendar.Component,
        referenceDate: Date
    ) -> [BloodPressurePoint] {

        guard let interval = calendar.dateInterval(of: component, for: referenceDate) else {
            return []
        }

        let grouped = Dictionary(grouping: self.filter {
            interval.contains($0.date)
        }) {
            calendar.startOfDay(for: $0.date)
        }

        return grouped.compactMap { _, entries in
            guard let last = entries.max(by: { $0.date < $1.date }) else { return nil }
            return BloodPressurePoint(
                date: last.date,
                systolic: last.systolic,
                diastolic: last.diastolic
            )
        }
        .sorted { $0.date < $1.date }
    }

    func forWeek(_ date: Date) -> [BloodPressurePoint] {
        lastPerDay(component: .weekOfYear, referenceDate: date)
    }

    func forMonth(_ date: Date) -> [BloodPressurePoint] {
        lastPerDay(component: .month, referenceDate: date)
    }

    // YEAR → her ayın SON ölçümü
    func forYear(_ date: Date) -> [BloodPressurePoint] {
        guard let interval = calendar.dateInterval(of: .year, for: date) else {
            return []
        }

        let grouped = Dictionary(grouping: self.filter {
            interval.contains($0.date)
        }) {
            calendar.dateComponents([.year, .month], from: $0.date)
        }

        return grouped.compactMap { components, entries in
            guard
                let monthDate = calendar.date(from: components),
                let last = entries.max(by: { $0.date < $1.date })
            else { return nil }

            return BloodPressurePoint(
                date: monthDate,
                systolic: last.systolic,
                diastolic: last.diastolic
            )
        }
        .sorted { $0.date < $1.date }
    }
}

import Foundation
import SwiftUI
import HealthKit
import Charts
enum SleepStage: String, CaseIterable, Identifiable, Plottable {
	case inBed = "In Bed"
	case awake = "Awake"
	case light = "Light"
	case deep = "Deep"
	case rem = "REM"

	var id: String { self.rawValue }
	var primitivePlottable: String {
		self.rawValue
	}

	init?(primitivePlottable: String) {
		self.init(rawValue: primitivePlottable)
	}

	var color: Color {
		switch self {
			case .inBed: return .gray
			case .awake: return .orange
			case .light: return .cyan
			case .deep: return .indigo
			case .rem: return .purple
		}
	}

	static func from(hkValue: Int) -> SleepStage? {
		switch hkValue {
			case HKCategoryValueSleepAnalysis.inBed.rawValue: return .inBed
			case HKCategoryValueSleepAnalysis.awake.rawValue: return .awake
			case HKCategoryValueSleepAnalysis.asleepREM.rawValue: return .rem
			case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: return .deep
			case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
				HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
				return .light
			default: return nil
		}
	}
}
struct SleepStagePeriod: Identifiable, Equatable {
	let id = UUID()
	let type: SleepStage
	let startDate: Date
	let endDate: Date
	var duration: TimeInterval { endDate.timeIntervalSince(startDate) }
}
struct DailySleepAnalysis: Identifiable, Equatable {
	let id = UUID()
	let date: Date
	let stagePeriods: [SleepStagePeriod]

	var dateInterval: DateInterval? {
		guard let firstPeriod = stagePeriods.min(by: { $0.startDate < $1.startDate }),
			  let lastPeriod = stagePeriods.max(by: { $0.endDate < $1.endDate }) else {
			return nil
		}
		return DateInterval(start: firstPeriod.startDate, end: lastPeriod.endDate)
	}

	init(emptyFor date: Date) {
		self.date = date
		self.stagePeriods = []
	}

	init(date: Date, stagePeriods: [SleepStagePeriod]) {
		self.date = date
		self.stagePeriods = stagePeriods
	}

	var totalInBedTime: TimeInterval {
		guard let first = stagePeriods.min(by: { $0.startDate < $1.startDate }),
			  let last = stagePeriods.max(by: { $0.endDate < $1.endDate }) else { return 0 }
		return last.endDate.timeIntervalSince(first.startDate)
	}

	func duration(of stage: SleepStage) -> TimeInterval {
		stagePeriods.filter { $0.type == stage }.reduce(0) { $0 + $1.duration }
	}

	var totalAsleepTime: TimeInterval {
		duration(of: .light) + duration(of: .deep) + duration(of: .rem)
	}

	var sleepEfficiency: Double {
		guard totalInBedTime > 0 else { return 0 }
		return totalAsleepTime / totalInBedTime
	}

	var sleepScore: Int {
		let durationGoal: TimeInterval = 8 * 3600
		let durationRatio = min(totalAsleepTime / durationGoal, 1.0)
		let durationScore = durationRatio * 60

		guard totalAsleepTime > 0 else {
			return Int(durationScore)
		}

		let deepPercentage = duration(of: .deep) / totalAsleepTime
		let deepScore = (min(deepPercentage / 0.20, 1.0)) * 25

		let remPercentage = duration(of: .rem) / totalAsleepTime
		let remScore = (min(remPercentage / 0.25, 1.0)) * 15

		return Int(durationScore + deepScore + remScore)
	}

	static var mock: DailySleepAnalysis {
		let now = Calendar.current.startOfDay(for: .now)
		var periods: [SleepStagePeriod] = []

		let bedTime = Calendar.current.date(byAdding: .hour, value: -8, to: now)!

		periods.append(.init(type: .inBed, startDate: bedTime, endDate: now))
		periods.append(.init(type: .awake, startDate: bedTime, endDate: bedTime.addingTimeInterval(900)))
		periods.append(.init(type: .light, startDate: bedTime.addingTimeInterval(900), endDate: bedTime.addingTimeInterval(3600)))
		periods.append(.init(type: .deep, startDate: bedTime.addingTimeInterval(3600), endDate: bedTime.addingTimeInterval(7200)))
		periods.append(.init(type: .light, startDate: bedTime.addingTimeInterval(7200), endDate: bedTime.addingTimeInterval(10800)))
		periods.append(.init(type: .rem, startDate: bedTime.addingTimeInterval(10800), endDate: bedTime.addingTimeInterval(14400)))
		periods.append(.init(type: .light, startDate: bedTime.addingTimeInterval(14400), endDate: bedTime.addingTimeInterval(20000)))
		periods.append(.init(type: .deep, startDate: bedTime.addingTimeInterval(20000), endDate: bedTime.addingTimeInterval(23600)))
		periods.append(.init(type: .awake, startDate: bedTime.addingTimeInterval(23600), endDate: bedTime.addingTimeInterval(24200)))
		periods.append(.init(type: .light, startDate: bedTime.addingTimeInterval(24200), endDate: now))

		return DailySleepAnalysis(date: now, stagePeriods: periods)
	}
}

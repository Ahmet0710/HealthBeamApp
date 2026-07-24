import SwiftUI
import Charts
import HealthKit
struct HeartRateChartView: View {
	let samples: [HKQuantitySample]
	@State private var selectedSample: HKQuantitySample?
	@State private var dragLocation: CGPoint?
	private let bpmUnit = HKUnit.count().unitDivided(by: .minute())
	private var minBPM: Double {
		samples.map { $0.quantity.doubleValue(for: bpmUnit) }.min() ?? 40
	}
	private var maxBPM: Double {
		samples.map { $0.quantity.doubleValue(for: bpmUnit) }.max() ?? 100
	}
	var body: some View {
		Chart {
			chartContent
		}
		.chartYScale(domain: (minBPM - 10)...(maxBPM + 10))
		.chartYAxis {
			AxisMarks { value in
				AxisGridLine(); AxisTick()
				if let bpm = value.as(Double.self) {
					AxisValueLabel("\(Int(bpm))")
				}
			}
		}
		.chartXAxis(.hidden)
		.chartOverlay { proxy in
			gestureOverlay(proxy: proxy)
		}
		.overlay(alignment: .topLeading) {
			infoOverlay
		}
		.frame(height: 150)
	}
	@ChartContentBuilder
	private var chartContent: some ChartContent {
		ForEach(samples, id: \.uuid) { sample in
			let bpm = sample.quantity.doubleValue(for: bpmUnit)
			let time = sample.startDate
			AreaMark(x: .value("Time", time), y: .value("BPM", bpm))
				.foregroundStyle(LinearGradient(gradient: Gradient(colors: [.pink.opacity(0.4), .pink.opacity(0.0)]), startPoint: .top, endPoint: .bottom))
				.interpolationMethod(.monotone)
			LineMark(x: .value("Time", time), y: .value("BPM", bpm))
				.foregroundStyle(Color.pink)
				.interpolationMethod(.monotone)
				.symbol(Circle())
		}
		if let selected = selectedSample {
			PointMark(
				x: .value("Time", selected.startDate),
				y: .value("BPM", selected.quantity.doubleValue(for: bpmUnit))
			)
			.symbolSize(CGSize(width: 12, height: 12))
			.foregroundStyle(.white)
			.annotation(position: .overlay) {
				Circle().stroke(Color.pink, lineWidth: 2).frame(width: 20, height: 20)
			}
		}
	}
	@ViewBuilder
	private var infoOverlay: some View {
		if let selected = selectedSample {
			VStack(alignment: .leading, spacing: 2) {
				Text(selected.startDate.formatted(.dateTime.hour().minute()))
					.font(.caption)
					.foregroundStyle(.secondary)
				Text("\(Int(selected.quantity.doubleValue(for: bpmUnit))) BPM")
					.font(.headline.bold())
					.foregroundStyle(.primary)
			}
			.padding(8)
			.background(Color(uiColor: .systemBackground).opacity(0.8), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
			.shadow(radius: 3)
			.padding(.leading)
		}
	}
	private func gestureOverlay(proxy: ChartProxy) -> some View {
		GeometryReader { geometry in
			ZStack {
				Rectangle().fill(.clear).contentShape(Rectangle())
					.gesture(
						DragGesture(minimumDistance: 0)
							.onChanged { value in
								let closestSample = findClosestSample(to: value.location, proxy: proxy, geometry: geometry)
								if self.selectedSample?.startDate != closestSample?.startDate {
									UIImpactFeedbackGenerator(style: .light).impactOccurred()
								}
								self.selectedSample = closestSample
								self.dragLocation = value.location
							}
							.onEnded { _ in
								self.selectedSample = nil
								self.dragLocation = nil
							}
					)
				if let selected = selectedSample {
					let frame = getPlotFrame(proxy: proxy, geometry: geometry)
					if !frame.isEmpty {
						let xPos = proxy.position(forX: selected.startDate) ?? 0
						Rectangle()
							.fill(Color.gray.opacity(0.5))
							.frame(width: 1, height: frame.size.height)
							.offset(x: xPos + frame.origin.x, y: frame.origin.y)
					}
				}
			}
		}
	}
	private func getPlotFrame(proxy: ChartProxy, geometry: GeometryProxy) -> CGRect {
		if #available(iOS 17.0, *) {
			if let plotFrameAnchor = proxy.plotFrame {
				return geometry[plotFrameAnchor]
			} else {
				return .zero
			}
		} else {
			return geometry[proxy.plotAreaFrame]
		}
	}
	private func findClosestSample(to point: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> HKQuantitySample? {
		let relativeXPosition = point.x - geometry.frame(in: .local).origin.x
		if let date: Date = proxy.value(atX: relativeXPosition), !samples.isEmpty {
			return samples.min(by: { abs($0.startDate.timeIntervalSince(date)) < abs($1.startDate.timeIntervalSince(date)) })
		}
		return nil
	}
}

import SwiftUI
import Charts

struct ECGInteractiveReaderView: View {
    let data: [ECGPoint]
    let date: Date
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let totalHeight = geo.size.height
                let totalWidth = geo.size.width
                let headerHeight: CGFloat = 60
                let footerHeight: CGFloat = 30
                let graphHeight = max(0, (totalHeight - headerHeight - footerHeight) / 3)

                ZStack(alignment: .top) {
                    ZoomableScrollView {
                        VStack(spacing: 0) {
                            Spacer().frame(height: headerHeight)
                            ECGStripView(data: data, range: 0...10)
                                .frame(height: graphHeight)
                                .frame(width: totalWidth)
                            ECGStripView(data: data, range: 10...20)
                                .frame(height: graphHeight)
                                .frame(width: totalWidth)
                            ECGStripView(data: data, range: 20...30)
                                .frame(height: graphHeight)
                                .frame(width: totalWidth)
                            HStack {
                                Text("25 mm/s")
                                Spacer()
                                Text("10 mm/mV")
                                Spacer()
                                Text("Lead I")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .frame(height: footerHeight)
                        }
                        .background(Color.white)
                    }
                    .ignoresSafeArea()
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(date.formatted(date: .omitted, time: .shortened))
                                .font(.system(.body, design: .rounded).bold())
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.gray.opacity(0.5))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .frame(height: headerHeight, alignment: .bottom)
                    .background(.ultraThinMaterial)
                }
            }
            .background(Color.white)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

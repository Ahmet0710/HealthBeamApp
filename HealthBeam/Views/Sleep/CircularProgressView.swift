import SwiftUI
struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: lineWidth
                )
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90)) 
                .animation(.easeOut(duration: 1.0), value: progress)
        }
    }
}

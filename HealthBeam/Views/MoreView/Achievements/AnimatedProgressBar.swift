import SwiftUI

struct AnimatedProgressBar: View {
    let value: Double
    let color: Color
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().frame(width: geometry.size.width, height: 8).foregroundColor(color.opacity(0.2))
                Capsule().frame(width: geometry.size.width * value, height: 8).foregroundColor(color)
            }
        }
        .frame(height: 8)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
    }
}

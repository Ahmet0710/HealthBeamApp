import SwiftUI

struct ECGGridBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let smallStep: CGFloat = 10
                for x in stride(from: 0, to: width, by: smallStep) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                for y in stride(from: 0, to: height, by: smallStep) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color.red.opacity(0.15), lineWidth: 0.5)
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let bigStep: CGFloat = 50
                for x in stride(from: 0, to: width, by: bigStep) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                for y in stride(from: 0, to: height, by: bigStep) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color.red.opacity(0.3), lineWidth: 1)
        }
        .background(Color.white)
    }
}

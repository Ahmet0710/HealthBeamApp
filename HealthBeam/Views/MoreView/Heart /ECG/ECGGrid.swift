import SwiftUI

struct ECGGrid: View {
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let majorGridCountX = 50
            let stepX = width / CGFloat(majorGridCountX)
            let stepY = stepX
            var pathSmall = Path()
            var pathMajor = Path()
            for i in 0...Int(width / (stepX / 5)) {
                let x = CGFloat(i) * (stepX / 5)
                if i % 5 == 0 {
                    pathMajor.move(to: CGPoint(x: x, y: 0))
                    pathMajor.addLine(to: CGPoint(x: x, y: height))
                } else {
                    pathSmall.move(to: CGPoint(x: x, y: 0))
                    pathSmall.addLine(to: CGPoint(x: x, y: height))
                }
            }
            for i in 0...Int(height / (stepY / 5)) {
                let y = CGFloat(i) * (stepY / 5)
                if i % 5 == 0 {
                    pathMajor.move(to: CGPoint(x: 0, y: y))
                    pathMajor.addLine(to: CGPoint(x: width, y: y))
                } else {
                    pathSmall.move(to: CGPoint(x: 0, y: y))
                    pathSmall.addLine(to: CGPoint(x: width, y: y))
                }
            }
            context.stroke(pathSmall, with: .color(Color.gray.opacity(0.2)), lineWidth: 0.5)
            context.stroke(pathMajor, with: .color(Color.gray.opacity(0.4)), lineWidth: 1.0)
        }
        .background(Color.white)
    }
}

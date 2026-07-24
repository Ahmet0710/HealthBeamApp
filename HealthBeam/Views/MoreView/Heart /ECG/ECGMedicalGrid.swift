import SwiftUI

struct ECGMedicalGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        return path
    }
}

struct ECGMedicalGridLines: View {
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let smallGridSize: CGFloat = 15
            let majorGridCount = 5
            var pathSmall = Path()
            var pathMajor = Path()
            for i in 0...Int(width / smallGridSize) {
                let x = CGFloat(i) * smallGridSize
                if i % majorGridCount == 0 {
                    pathMajor.move(to: CGPoint(x: x, y: 0))
                    pathMajor.addLine(to: CGPoint(x: x, y: height))
                } else {
                    pathSmall.move(to: CGPoint(x: x, y: 0))
                    pathSmall.addLine(to: CGPoint(x: x, y: height))
                }
            }
            for i in 0...Int(height / smallGridSize) {
                let y = CGFloat(i) * smallGridSize
                if i % majorGridCount == 0 {
                    pathMajor.move(to: CGPoint(x: 0, y: y))
                    pathMajor.addLine(to: CGPoint(x: width, y: y))
                } else {
                    pathSmall.move(to: CGPoint(x: 0, y: y))
                    pathSmall.addLine(to: CGPoint(x: width, y: y))
                }
            }
            context.stroke(pathSmall, with: .color(.red.opacity(0.15)), lineWidth: 0.5)
            context.stroke(pathMajor, with: .color(.red.opacity(0.4)), lineWidth: 1.0)
        }
        .background(Color.red.opacity(0.02))
    }
}

#Preview {
    ECGMedicalGridLines()
        .frame(width: 300, height: 300)
}

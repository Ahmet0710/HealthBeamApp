import SwiftUI

struct ConfettiView: View {
    @State private var particles: [Particle] = []
    let colors: [Color] = [.red, .green, .blue, .yellow, .orange, .purple]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .scaleEffect(particle.scale)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
            .onAppear { createConfetti(screenSize: geometry.size) }
        }
    }

    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var color: Color
        var size: CGFloat
        var opacity: Double
        var scale: Double
        var rotation: Double
    }

    private func createConfetti(screenSize: CGSize) {
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        let numberOfParticles = 50 

        for _ in 0..<numberOfParticles {
            let initialPosition = CGPoint(x: screenWidth / 2, y: screenHeight / 4)
            let targetX = CGFloat.random(in: 0...screenWidth)
            let targetY = CGFloat.random(in: screenHeight * 0.5...screenHeight * 1.5)

            let particle = Particle(
                position: initialPosition,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 5...15),
                opacity: 1.0,
                scale: 1.0,
                rotation: 0
            )
            particles.append(particle)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                withAnimation(.easeOut(duration: Double.random(in: 1.5...3.0))) {
                    if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                        particles[index].position = CGPoint(x: targetX, y: targetY)
                        particles[index].opacity = 0.0
                        particles[index].scale = 0.5
                        particles[index].rotation = Double.random(in: 0...360)
                    }
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            particles.removeAll()
        }
    }
}

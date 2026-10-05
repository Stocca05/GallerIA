import SwiftUI

struct ConfettiView: View {
    @State private var particles: [Particle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let elapsedTime = time - particle.delay
                    guard elapsedTime > 0 else { continue }
                    let progress = elapsedTime / particle.duration
                    if progress > 1 { continue }

                    let y = size.height * CGFloat(progress)
                    let xOffset = sin(time * particle.phase) * 50
                    let position = CGPoint(x: CGFloat(particle.x) * size.width + xOffset, y: y)

                    let rotation = Angle(degrees: time * particle.phase * 180)
                    context.translateBy(x: position.x, y: position.y)
                    context.rotate(by: rotation)

                    let color: Color = [.yellow, .orange, .pink, .cyan, .purple].randomElement()!
                    context.fill(Path(ellipseIn: CGRect(x: -particle.radius, y: -particle.radius, width: particle.radius * 2, height: particle.radius * 2)), with: .color(color))

                    context.rotate(by: -rotation)
                    context.translateBy(x: -position.x, y: -position.y)
                }
            }
        }
        .onAppear {
            particles = (0..<80).map { _ in
                Particle(
                    x: Double.random(in: 0...1),
                    delay: CFAbsoluteTimeGetCurrent() + Double.random(in: 0...1.0),
                    duration: Double.random(in: 2...4),
                    radius: CGFloat.random(in: 4...8),
                    phase: Double.random(in: 1...5)
                )
            }
        }
    }

    private struct Particle {
        let x: Double
        let delay: Double
        let duration: Double
        let radius: CGFloat
        let phase: Double
    }
}

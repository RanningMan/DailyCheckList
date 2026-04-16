import SwiftUI

struct FlameParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var color: Color
}

struct BurnEffectModifier: ViewModifier {
    let isTriggered: Bool
    @Environment(\.appTheme) private var theme
    @State private var particles: [FlameParticle] = []
    @State private var showFlash = false

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    // Neon flash
                    if showFlash {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.completedAccent.opacity(0.15))
                            .transition(.opacity)
                    }

                    // Flame particles
                    ForEach(particles) { particle in
                        Text("🔥")
                            .font(.system(size: 14 * particle.scale))
                            .opacity(particle.opacity)
                            .offset(x: particle.x, y: particle.y)
                    }
                }
                .allowsHitTesting(false)
            }
            .onChange(of: isTriggered) { oldValue, newValue in
                if !oldValue && newValue {
                    triggerBurn()
                }
            }
    }

    private func triggerBurn() {
        // Flash
        withAnimation(.easeIn(duration: 0.1)) {
            showFlash = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            showFlash = false
        }

        // Spawn particles
        let count = 8
        var newParticles: [FlameParticle] = []
        for _ in 0..<count {
            newParticles.append(FlameParticle(
                x: CGFloat.random(in: -20...20),
                y: 0,
                scale: CGFloat.random(in: 0.6...1.2),
                opacity: 1.0,
                color: [theme.completedAccent, .orange, .red, .yellow].randomElement()!
            ))
        }
        particles = newParticles

        // Animate particles rising and fading
        withAnimation(.easeOut(duration: 0.7)) {
            particles = particles.map { p in
                var updated = p
                updated.y = CGFloat.random(in: -40 ... -20)
                updated.x = p.x + CGFloat.random(in: -15...15)
                updated.opacity = 0
                updated.scale = p.scale * 0.3
                return updated
            }
        }

        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            particles = []
        }
    }
}

extension View {
    func burnEffect(isTriggered: Bool) -> some View {
        modifier(BurnEffectModifier(isTriggered: isTriggered))
    }
}

import SwiftUI

struct BreathingModifier: ViewModifier {
    @State private var isBreathing = false

    var duration: Double = 2.0
    var scaleAmount: CGFloat = 1.05
    var opacityAmount: Double = 0.8

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? scaleAmount : 1.0)
            .opacity(isBreathing ? opacityAmount : 1.0)
            .animation(
                Animation.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true),
                value: isBreathing
            )
            .onAppear {
                isBreathing = true
            }
    }
}

extension View {
    func breathing(duration: Double = 2.0, scaleAmount: CGFloat = 1.05, opacityAmount: Double = 0.8) -> some View {
        self.modifier(BreathingModifier(duration: duration, scaleAmount: scaleAmount, opacityAmount: opacityAmount))
    }
}

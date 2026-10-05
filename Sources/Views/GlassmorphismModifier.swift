import SwiftUI

struct GlassmorphismModifier: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(opacity), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}

extension View {
    func glassmorphism(cornerRadius: CGFloat = 16, borderOpacity: Double = 0.2) -> some View {
        self.modifier(GlassmorphismModifier(cornerRadius: cornerRadius, opacity: borderOpacity))
    }
}

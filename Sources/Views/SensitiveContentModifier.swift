import SwiftUI

struct SensitiveContentModifier: ViewModifier {
    let isNSFW: Bool
    @State private var isRevealed = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if isNSFW && !isRevealed {
                    ZStack {
                        Color.black.opacity(0.85)

                        Rectangle()
                            .fill(.ultraThinMaterial)

                        VStack(spacing: 8) {
                            Image(systemName: "eye.slash.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            Text("Contenuto Sensibile")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isRevealed = true
                        }
                        HapticSymphonyManager.shared.playSuccessRipple()
                    }
                }
            }
    }
}

extension View {
    func censorSensitiveContent(isNSFW: Bool) -> some View {
        self.modifier(SensitiveContentModifier(isNSFW: isNSFW))
    }
}

import SwiftUI
import UIKit

struct CardView: View {
    let image: UIImage
    let score: Float
    var isCleanup = false
    let onSwipe: (Bool) -> Void

    @State private var offset: CGSize = .zero
    @State private var isDismissing = false

    private var swipeLabel: String {
        if isCleanup {
            return offset.width > 0 ? "ELIMINA" : "SALVA"
        } else {
            return offset.width > 0 ? "MI PIACE" : "NON FA PER ME"
        }
    }

    private var swipeColor: Color {
        if isCleanup {
            return offset.width > 0 ? .red : .green
        } else {
            return offset.width > 0 ? .green : .red
        }
    }

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: 480)
            .frame(height: 380)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
            .overlay(alignment: .topLeading) {
                if offset.width != 0 {
                    Text(swipeLabel)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(swipeColor)
                        .clipShape(Capsule())
                        .opacity(min(Double(abs(offset.width) / 100), 1))
                        .padding(20)
                }
            }
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .scaleEffect(max(0.85, 1.0 - abs(Double(offset.width) / 800)))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !isDismissing else { return }
                        let crossedThreshold = abs(value.translation.width) > 100
                        let wasBelowThreshold = abs(offset.width) <= 100
                        if crossedThreshold && wasBelowThreshold {
                            UISelectionFeedbackGenerator().selectionChanged()
                        } else if !crossedThreshold && !wasBelowThreshold {
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                        offset = value.translation
                    }
                    .onEnded { _ in
                        guard !isDismissing else { return }
                        if offset.width > 100 {
                            isDismissing = true
                            // Liked — fly right
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            SoundManager.shared.playSwipeRight()
                            withAnimation(.easeOut(duration: 0.25)) {
                                offset = CGSize(width: 500, height: offset.height)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onSwipe(true)
                            }
                        } else if offset.width < -100 {
                            isDismissing = true
                            // Disliked — fly left
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            SoundManager.shared.playSwipeLeft()
                            withAnimation(.easeOut(duration: 0.25)) {
                                offset = CGSize(width: -500, height: offset.height)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onSwipe(false)
                            }
                        } else {
                            // Snap back
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                offset = .zero
                            }
                        }
                    }
            )
            .accessibilityLabel("Foto")
            .accessibilityValue("Score: \(Int(score * 100))%")
    }
}

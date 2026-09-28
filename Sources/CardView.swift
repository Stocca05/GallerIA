import SwiftUI
import UIKit

struct CardView: View {
    let image: UIImage
    let score: Float
    var isCleanup = false
    let onSwipe: (Bool) -> Void

    @State private var offset: CGSize = .zero

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 300, height: 400)
            .cornerRadius(20)
            .shadow(radius: 10)
            .overlay(alignment: .topLeading) {
                if offset.width != 0 {
                    Text(isCleanup
                         ? (offset.width > 0 ? "ELIMINA" : "SALVA")
                         : (offset.width > 0 ? "BELLA" : "BRUTTA"))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background((offset.width > 0) != isCleanup ? Color.green : Color.red)
                        .clipShape(Capsule())
                        .opacity(min(Double(abs(offset.width) / 100), 1))
                        .padding(20)
                }
            }
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
                    .onEnded { _ in
                        if offset.width > 100 {
                            onSwipe(true)
                        } else if offset.width < -100 {
                            onSwipe(false)
                        } else {
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                    }
            )
            .accessibilityLabel("Foto")
            .accessibilityValue("Score: \(score.formatted(.percent.precision(.fractionLength(0))))")
    }
}

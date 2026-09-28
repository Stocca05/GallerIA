import SwiftUI

struct GalleryCellView: View {
    let image: UIImage
    let score: Float

    var body: some View {
        ShareLink(
            item: Image(uiImage: image),
            preview: SharePreview("Scelto dall'IA", image: Image(uiImage: image))
        ) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .overlay(alignment: .bottomTrailing) {
                    HStack(spacing: 4) {
                        if score >= 0.8 {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .shadow(color: .yellow, radius: 2)
                        }
                        Text("\(Int(score * 100))%")
                            .foregroundColor(.white)
                    }
                    .font(.caption2.bold())
                    .padding(6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(6)
                }
        }
    }
}

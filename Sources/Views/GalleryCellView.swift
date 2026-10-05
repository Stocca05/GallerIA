import SwiftUI

struct GalleryCellView: View {
    let image: UIImage
    let score: Float

    @State private var hasFaces = false

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .overlay(alignment: .topLeading) {
                if hasFaces {
                    Image(systemName: "face.smiling.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(6)
                }
            }
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
            .task {
                if let cgImage = image.cgImage {
                    hasFaces = await FaceDetectionManager.shared.hasFaces(in: cgImage)
                }
            }
    }
}

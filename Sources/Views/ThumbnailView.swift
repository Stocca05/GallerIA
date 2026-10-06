import SwiftUI
import Photos

struct ThumbnailView: View {
    let asset: PHAsset
    let size: CGFloat

    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
            }
        }
        .task(id: asset.localIdentifier) {
            image = nil
            image = await PhotoImageLoader.image(for: asset, size: CGSize(width: size * 2, height: size * 2))
        }
    }
}

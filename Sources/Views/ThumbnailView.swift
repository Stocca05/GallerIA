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
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: size * 2, height: size * 2), // Retain size
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result = result {
                self.image = result
            }
        }
    }
}

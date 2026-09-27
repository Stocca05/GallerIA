import SwiftUI
import Photos
import UIKit

struct GalleryView: View {
    let classifier: AestheticClassifier
    let mlManager: MLManager

    @State private var scoredImages: [(UIImage, Float)] = []

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                ForEach(scoredImages.indices, id: \.self) { index in
                    let (image, score) = scoredImages[index]

                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                        .overlay(alignment: .bottomTrailing) {
                            Text("\(Int(score * 100))%")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(4)
                                .background(.black.opacity(0.65), in: Capsule())
                                .padding(4)
                        }
                }
            }
            .padding()
        }
        .task {
            let loadingTask = Task.detached(priority: .userInitiated) { [classifier, mlManager] in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.fetchLimit = 100
                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

                let options = PHImageRequestOptions()
                options.isSynchronous = true
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .exact

                let imageManager = PHImageManager.default()
                var results: [(UIImage, Float)] = []

                for index in 0..<assets.count {
                    guard !Task.isCancelled else { break }

                    autoreleasepool {
                        var thumbnail: UIImage?
                        imageManager.requestImage(
                            for: assets.object(at: index),
                            targetSize: CGSize(width: 300, height: 300),
                            contentMode: .aspectFit,
                            options: options
                        ) { image, _ in
                            thumbnail = image
                        }

                        guard let image = thumbnail,
                              let cgImage = image.cgImage,
                              let embedding = mlManager.extractEmbedding(from: cgImage) else { return }

                        results.append((image, classifier.predict(embedding: embedding)))
                    }
                }

                return results.sorted { $0.1 > $1.1 }
            }

            let images = await withTaskCancellationHandler {
                await loadingTask.value
            } onCancel: {
                loadingTask.cancel()
            }

            guard !Task.isCancelled else { return }
            scoredImages = images
        }
    }
}

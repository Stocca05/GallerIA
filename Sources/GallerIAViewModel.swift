import SwiftUI
import Photos
import StoreKit

@MainActor
class GallerIAViewModel: ObservableObject {
    @Published var currentImage: UIImage?
    @Published var currentScore: Float = 0.5
    @Published var isFinished = false

    let photoManager = PhotoManager()
    let mlManager = MLManager()
    let embeddingCache = EmbeddingCache()
    let classifier = AestheticClassifier()
    var currentEmbedding: [Float]? = nil
    var photosRated: Int = 0

    private var imageRequestID = UUID()

    func loadNextPhoto() {
        let requestID = UUID()
        imageRequestID = requestID
        currentEmbedding = nil
        currentScore = 0.5

        Task.detached(priority: .userInitiated) { [weak self] in
            let asset = await MainActor.run { [weak self] () -> PHAsset? in
                guard let self, self.imageRequestID == requestID else { return nil }
                guard !self.photoManager.assets.isEmpty else {
                    self.isFinished = true
                    self.currentImage = nil
                    return nil
                }
                return self.photoManager.assets.removeFirst()
            }
            guard let asset else { return }

            // Process only the final image, avoiding races with preview callbacks.
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 800, height: 800),
                contentMode: .aspectFit,
                options: options
            ) { [weak self] image, info in
                guard (info?[PHImageResultIsDegradedKey] as? Bool) != true else { return }
                Task { @MainActor [weak self] in
                    guard let self, self.imageRequestID == requestID else { return }
                    self.currentImage = image
                    guard let cgImage = image?.cgImage else { return }

                    let embedding = await Task.detached(priority: .userInitiated) { () -> [Float]? in
                        let mlManager = self.mlManager
                        let embeddingCache = self.embeddingCache
                        let id = asset.localIdentifier
                        if let cached = embeddingCache.getEmbedding(for: id) {
                            return cached
                        }
                        guard let extracted = mlManager.extractEmbedding(from: cgImage) else {
                            return nil
                        }
                        embeddingCache.saveEmbedding(extracted, for: id)
                        return extracted
                    }.value

                    // Ignore results if a swipe or reset occurred during extraction.
                    guard self.imageRequestID == requestID, let embedding else { return }
                    self.currentEmbedding = embedding
                    // predict mutates weights; serialize it with update and reset.
                    self.currentScore = self.classifier.predict(embedding: embedding)
                }
            }
        }
    }

    func resetBrain() {
        imageRequestID = UUID()
        currentEmbedding = nil
        currentScore = 0.5
        classifier.reset()
        isFinished = false
        currentImage = nil
        photoManager.requestAccessAndFetch()
    }

    func rate(liked: Bool) {
        photosRated += 1
        if photosRated == 20 {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview()
            }
        }

        if let currentEmbedding = currentEmbedding {
            let label: Float = liked ? 1.0 : 0.0
            classifier.update(embedding: currentEmbedding, label: label)
        }

        loadNextPhoto()
    }
}

import SwiftUI
import Photos

class GallerIAViewModel: ObservableObject {
    @Published var currentImage: UIImage?
    @Published var currentScore: Float = 0.5
    @Published var isFinished = false

    let photoManager = PhotoManager()
    let mlManager = MLManager()
    let classifier = AestheticClassifier()
    var currentEmbedding: [Float]? = nil

    func loadNextPhoto() {
        guard !photoManager.assets.isEmpty else {
            DispatchQueue.main.async {
                self.isFinished = true
                self.currentImage = nil
            }
            return
        }

        let asset = photoManager.assets.removeFirst()
        currentEmbedding = nil
        currentScore = 0.5

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 800, height: 800),
            contentMode: .aspectFit,
            options: nil
        ) { [weak self] image, _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.currentImage = image
                self.currentEmbedding = nil
                self.currentScore = 0.5

                if let cgImage = image?.cgImage,
                   let embedding = self.mlManager.extractEmbedding(from: cgImage) {
                    self.currentEmbedding = embedding
                    self.currentScore = self.classifier.predict(embedding: embedding)
                }
            }
        }
    }

    func rate(liked: Bool) {
        if let currentEmbedding = currentEmbedding {
            let label: Float = liked ? 1.0 : 0.0
            classifier.update(embedding: currentEmbedding, label: label)
        }

        loadNextPhoto()
    }
}

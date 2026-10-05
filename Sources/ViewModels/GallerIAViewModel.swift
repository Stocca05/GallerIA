import SwiftUI
import Photos
import StoreKit

@MainActor
class GallerIAViewModel: ObservableObject {
    // MARK: - Published state
    @Published var cardQueue: [PhotoCard] = []
    @Published var isFinished = false
    @Published var pendingTrainings: Int = 0
    @Published var isTraining = false
    @Published var trashCount: Int = 0
    @Published var photosRated: Int = 0
    @Published var isLoading = false

    // MARK: - Dependencies
    let photoManager = PhotoManager()
    let mlManager = MLManager()
    let embeddingCache = EmbeddingCache()
    let classifier = AestheticClassifier()

    // MARK: - Internal state
    var undoHistory: [(PhotoCard, Bool)] = []
    var pendingTrash: [PHAsset] = []
    private let prefetchCount = 5

    // MARK: - Computed
    var topCard: PhotoCard? { cardQueue.first }

    // MARK: - Queue management

    func reloadSession() {
        if !classifier.batchEmbeddings.isEmpty { performTraining() }
        cardQueue.removeAll()
        undoHistory.removeAll()
        isFinished = false
        startSession()
    }

    func startSession() {
        isLoading = true
        fillQueue()
    }

    func fillQueue() {
        // Load more batches if running low
        if photoManager.assets.count < prefetchCount && photoManager.hasMoreBatches {
            photoManager.loadNextBatch()
        }

        while cardQueue.count < prefetchCount, !photoManager.assets.isEmpty {
            let asset = photoManager.assets.removeFirst()
            let card = PhotoCard(id: asset.localIdentifier, asset: asset)
            cardQueue.append(card)
            prefetchImage(for: card)
        }

        if cardQueue.isEmpty && !photoManager.hasMoreBatches && photoManager.assets.isEmpty {
            // Flush any remaining training data before finishing
            if !classifier.batchEmbeddings.isEmpty {
                performTraining()
            }
            isFinished = true
        }

        isLoading = false
    }

    private func prefetchImage(for card: PhotoCard) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(
            for: card.asset,
            targetSize: CGSize(width: 600, height: 600),
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, info in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let index = self.cardQueue.firstIndex(where: { $0.id == card.id }) else { return }

                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) == true

                // Always accept first image; upgrade to non-degraded
                if self.cardQueue[index].image == nil || !isDegraded {
                    self.cardQueue[index].image = image
                }

                guard let cgImage = image?.cgImage else { return }

                // Only extract embedding once
                if self.cardQueue[index].embedding == nil {
                    let embedding = await Task.detached(priority: .userInitiated) { () -> [Float]? in
                        let id = card.asset.localIdentifier
                        if let cached = self.embeddingCache.getEmbedding(for: id) {
                            return cached
                        }
                        guard let extracted = self.mlManager.extractEmbedding(from: cgImage) else {
                            return nil
                        }
                        self.embeddingCache.saveEmbedding(extracted, for: id)
                        return extracted
                    }.value

                    guard let embedding else { return }
                    // Re-check index in case queue changed
                    guard let newIndex = self.cardQueue.firstIndex(where: { $0.id == card.id }) else { return }
                    self.cardQueue[newIndex].embedding = embedding
                    self.cardQueue[newIndex].score = self.classifier.predict(embedding: embedding)
                }
            }
        }
    }

    // MARK: - Rating

    func rate(liked: Bool, expectedID: String? = nil) {
        if let expectedID, cardQueue.first?.id != expectedID { return }
        guard let first = cardQueue.first, first.image != nil, first.embedding != nil, !isTraining else { return }
        let currentCard = cardQueue.removeFirst()

        photosRated += 1

        if let embedding = currentCard.embedding {
            let label: Float = liked ? 1.0 : 0.0
            classifier.update(embedding: embedding, label: label)
            pendingTrainings = classifier.batchEmbeddings.count
            undoHistory.append((currentCard, liked))

            HistoryManager.shared.markAsRated(currentCard.asset.localIdentifier)

            // Auto-train every 10 ratings
            if classifier.batchEmbeddings.count >= 10 {
                performTraining()
            }
        }

        fillQueue()
    }

    func skipCurrentPhoto() {
        guard !cardQueue.isEmpty, !isTraining else { return }
        cardQueue.removeFirst()
        fillQueue()
    }

    // MARK: - Undo

    func undoLast() {
        guard !undoHistory.isEmpty else { return }
        if classifier.undoLastUpdate() {
            let (lastCard, liked) = undoHistory.removeLast()

            HistoryManager.shared.unmarkAsRated(lastCard.asset.localIdentifier)

            if !liked, !pendingTrash.isEmpty {
                pendingTrash.removeLast()
                trashCount = pendingTrash.count
            }

            // Put current queue items back
            let currentAssets = cardQueue.map(\.asset)
            cardQueue.removeAll()

            photoManager.assets.insert(contentsOf: currentAssets, at: 0)
            photoManager.assets.insert(lastCard.asset, at: 0)

            photosRated = max(0, photosRated - 1)
            pendingTrainings = classifier.batchEmbeddings.count
            isFinished = false
            fillQueue()
        }
    }

    // MARK: - Training

    func performTraining() {
        guard !classifier.batchEmbeddings.isEmpty else { return }
        isTraining = true

        pendingTrash.removeAll()
        trashCount = 0
        undoHistory.removeAll()

        classifier.flushBatch()
        pendingTrainings = 0

        // Refresh scores on queued cards with new weights
        for i in cardQueue.indices {
            if let embedding = cardQueue[i].embedding {
                cardQueue[i].score = classifier.predict(embedding: embedding)
            }
        }

        // Brief visual feedback, then dismiss
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            isTraining = false
        }
    }

    // MARK: - Reset

    func resetBrain() {
        cardQueue.removeAll()
        undoHistory.removeAll()
        pendingTrash.removeAll()
        trashCount = 0
        pendingTrainings = 0
        photosRated = 0
        classifier.reset()
        HistoryManager.shared.reset()
        isFinished = false
        isLoading = true
        photoManager.requestAccessAndFetch()
    }

    // MARK: - Continue training

    func continueTraining() {
        photoManager.loadNextBatch()
        if !photoManager.assets.isEmpty {
            isFinished = false
            fillQueue()
        }
    }
}

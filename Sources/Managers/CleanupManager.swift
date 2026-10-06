import Photos
import SwiftUI

struct DuplicateGroup: Identifiable {
    var id: String { original.localIdentifier }
    let assets: [PHAsset]
    let original: PHAsset
}

@MainActor
final class CleanupManager: ObservableObject {
    @Published var duplicates: [DuplicateGroup] = []
    @Published var screenshots: [PHAsset] = []
    @Published var largeVideos: [PHAsset] = []
    @Published private(set) var isScanning = false
    @Published private(set) var processed = 0
    @Published private(set) var total = 0
    @Published private(set) var skipped = 0
    @Published private(set) var statusMessage: String?
    @Published private(set) var lastScan: Date?

    let mlManager: MLManager
    private var scanTask: Task<Void, Never>?
    private var generation = UUID()
    private let cache = EmbeddingCache.shared

    init(mlManager: MLManager) { self.mlManager = mlManager }

    func cancelScan() {
        generation = UUID()
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        statusMessage = "Analisi interrotta. Puoi riavviarla quando vuoi."
    }

    func clearResults() {
        cancelScan()
        duplicates = []
        screenshots = []
        largeVideos = []
        processed = 0
        total = 0
        skipped = 0
        lastScan = nil
        statusMessage = nil
    }

    func startCleanupScan() {
        guard !isScanning else { return }
        let permission = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard permission == .authorized || permission == .limited else { clearResults(); return }
        isScanning = true
        processed = 0
        skipped = 0
        statusMessage = nil
        let token = UUID()
        generation = token

        let photoOptions = PHFetchOptions()
        photoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        photoOptions.fetchLimit = 500
        let photos = PHAsset.fetchAssets(with: .image, options: photoOptions)
        total = photos.count

        let screenshotOptions = PHFetchOptions()
        screenshotOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
        screenshotOptions.sortDescriptors = photoOptions.sortDescriptors
        screenshotOptions.fetchLimit = 100
        screenshots = Self.array(PHAsset.fetchAssets(with: .image, options: screenshotOptions))

        let videoOptions = PHFetchOptions()
        videoOptions.sortDescriptors = photoOptions.sortDescriptors
        videoOptions.fetchLimit = 100
        largeVideos = Self.array(PHAsset.fetchAssets(with: .video, options: videoOptions))

        scanTask = Task { [weak self, mlManager, cache] in
            let worker = Task.detached(priority: .utility) { () -> ([DuplicateGroup], Int) in
                var embeddings: [(PHAsset, [Float])] = []
                var skipped = 0
                for index in 0..<photos.count {
                    guard !Task.isCancelled else { return ([], skipped) }
                    let asset = photos.object(at: index)
                    let cacheKey = "cleanup-v1-\(asset.localIdentifier)-\(asset.modificationDate?.timeIntervalSince1970 ?? 0)"
                    if let cached = cache.getEmbedding(for: cacheKey) {
                        embeddings.append((asset, cached))
                    } else if let image = await PhotoImageLoader.image(for: asset),
                              let cgImage = image.cgImage,
                              let embedding = mlManager.extractEmbedding(from: cgImage) {
                        cache.saveEmbedding(embedding, for: cacheKey)
                        embeddings.append((asset, embedding))
                    } else { skipped += 1 }
                    await self?.recordProgress(index + 1, skipped: skipped, token: token)
                }

                var groups: [DuplicateGroup] = []
                var visited = Set<String>()
                for i in embeddings.indices {
                    guard !Task.isCancelled else { return ([], skipped) }
                    let asset = embeddings[i].0
                    guard visited.insert(asset.localIdentifier).inserted else { continue }
                    var group = [asset]
                    for j in (i + 1)..<embeddings.count {
                        let other = embeddings[j].0
                        guard !visited.contains(other.localIdentifier) else { continue }
                        if mlManager.cosineSimilarity(embeddings[i].1, embeddings[j].1) > 0.95 {
                            group.append(other)
                            visited.insert(other.localIdentifier)
                        }
                    }
                    if group.count > 1 {
                        // Prefer a favorite, then the largest available pixel dimensions.
                        group.sort {
                            if $0.isFavorite != $1.isFavorite { return $0.isFavorite }
                            let lhs = Int64($0.pixelWidth) * Int64($0.pixelHeight)
                            let rhs = Int64($1.pixelWidth) * Int64($1.pixelHeight)
                            if lhs != rhs { return lhs > rhs }
                            return $0.localIdentifier < $1.localIdentifier
                        }
                        groups.append(DuplicateGroup(assets: group, original: group[0]))
                    }
                }
                return (groups, skipped)
            }
            let result = await withTaskCancellationHandler { await worker.value } onCancel: { worker.cancel() }
            guard let self, !Task.isCancelled, self.generation == token else { return }
            self.duplicates = result.0
            self.skipped = result.1
            self.lastScan = .now
            self.isScanning = false
            self.scanTask = nil
            self.statusMessage = result.1 > 0
                ? "\(result.1) foto non disponibili o non analizzabili. Aprile in Foto per scaricarle, poi riprova."
                : "Analisi completata. Nessuna foto è stata modificata."
        }
    }

    private func recordProgress(_ count: Int, skipped: Int, token: UUID) {
        guard generation == token else { return }
        processed = count
        self.skipped = skipped
    }

    func removeDeleted(_ ids: Set<String>) {
        // Invalidate an in-flight scan before it can restore obsolete assets.
        cancelScan()
        duplicates = duplicates.compactMap { group in
            let remaining = group.assets.filter { !ids.contains($0.localIdentifier) }
            guard remaining.count > 1 else { return nil }
            return DuplicateGroup(assets: remaining, original: remaining[0])
        }
        screenshots.removeAll { ids.contains($0.localIdentifier) }
        largeVideos.removeAll { ids.contains($0.localIdentifier) }
        statusMessage = "\(ids.count) elementi spostati in Eliminati di recente."
        NotificationCenter.default.post(name: .init("GallerIALibraryChanged"), object: nil)
    }

    private static func array(_ result: PHFetchResult<PHAsset>) -> [PHAsset] {
        result.objects(at: IndexSet(integersIn: 0..<result.count))
    }
}

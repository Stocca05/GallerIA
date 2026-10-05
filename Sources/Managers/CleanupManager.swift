import Foundation
import Photos
import SwiftUI

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let assets: [PHAsset]
    let original: PHAsset
}

@MainActor
class CleanupManager: ObservableObject {
    @Published var duplicates: [DuplicateGroup] = []
    @Published var screenshots: [PHAsset] = []
    @Published var largeVideos: [PHAsset] = []
    @Published var isScanning = false

    let mlManager: MLManager

    init(mlManager: MLManager) {
        self.mlManager = mlManager
    }

    func startCleanupScan() {
        guard !isScanning else { return }
        isScanning = true

        Task {
            // Fetch latest photos to check for duplicates (limit to 500 for performance)
            let photoOptions = PHFetchOptions()
            photoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            photoOptions.fetchLimit = 500
            let recentPhotos = PHAsset.fetchAssets(with: .image, options: photoOptions)

            // Find screenshots
            let screenshotOptions = PHFetchOptions()
            screenshotOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
            screenshotOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            screenshotOptions.fetchLimit = 100
            let screenshotAssets = PHAsset.fetchAssets(with: .image, options: screenshotOptions)
            var foundScreenshots: [PHAsset] = []
            screenshotAssets.enumerateObjects { asset, _, _ in
                foundScreenshots.append(asset)
            }

            // Find large videos
            let videoOptions = PHFetchOptions()
            videoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            videoOptions.fetchLimit = 100
            let videoAssets = PHAsset.fetchAssets(with: .video, options: videoOptions)
            var foundVideos: [PHAsset] = []
            videoAssets.enumerateObjects { asset, _, _ in
                foundVideos.append(asset) // Ideally filter by size, but PHAsset doesn't expose size directly without fetching resources. We'll just show recent videos for now as "large files" candidate.
            }

            // Find duplicates via embeddings
            var assetEmbeddings: [(PHAsset, [Float])] = []

            let loadingTask = Task.detached(priority: .userInitiated) { [mlManager] () -> [(PHAsset, [Float])] in
                var results: [(PHAsset, [Float])] = []
                for index in 0..<recentPhotos.count {
                    guard !Task.isCancelled else { break }
                    let asset = recentPhotos.object(at: index)

                    if let cgImage = await self.fetchCGImage(for: asset),
                       let embedding = mlManager.extractEmbedding(from: cgImage) {
                        results.append((asset, embedding))
                    }
                }
                return results
            }

            assetEmbeddings = await loadingTask.value

            // Group by similarity > 0.95
            var groups: [[PHAsset]] = []
            var visited = Set<String>()

            for i in 0..<assetEmbeddings.count {
                let assetA = assetEmbeddings[i].0
                if visited.contains(assetA.localIdentifier) { continue }

                var currentGroup: [PHAsset] = [assetA]
                visited.insert(assetA.localIdentifier)

                for j in (i + 1)..<assetEmbeddings.count {
                    let assetB = assetEmbeddings[j].0
                    if visited.contains(assetB.localIdentifier) { continue }

                    let sim = mlManager.cosineSimilarity(assetEmbeddings[i].1, assetEmbeddings[j].1)
                    if sim > 0.95 {
                        currentGroup.append(assetB)
                        visited.insert(assetB.localIdentifier)
                    }
                }

                if currentGroup.count > 1 {
                    groups.append(currentGroup)
                }
            }

            self.duplicates = groups.map { DuplicateGroup(assets: $0, original: $0.first!) }
            self.screenshots = foundScreenshots
            self.largeVideos = foundVideos
            self.isScanning = false
        }
    }

    private func fetchCGImage(for asset: PHAsset) async -> CGImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 300, height: 300),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image?.cgImage)
            }
        }
    }
}

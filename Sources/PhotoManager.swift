import Photos
import SwiftUI

@MainActor
class PhotoManager: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var accessDenied = false
    private var allAssetsResult: PHFetchResult<PHAsset>?
    private var currentIndex = 0

    func requestAccessAndFetch() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async { [weak self] in
                self?.accessDenied = status == .denied || status == .restricted
            }

            guard status == .authorized || status == .limited else { return }

            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let result = PHAsset.fetchAssets(with: .image, options: options)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.allAssetsResult = result
                self.currentIndex = 0
                self.assets = []
                self.loadNextBatch()
            }
        }
    }

    func loadNextBatch() {
        guard let allAssetsResult, currentIndex < allAssetsResult.count else { return }

        let endIndex = min(currentIndex + 50, allAssetsResult.count)
        let batch = (currentIndex..<endIndex).map { allAssetsResult.object(at: $0) }
        currentIndex = endIndex
        assets = batch
    }
}

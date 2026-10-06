import Photos
import SwiftUI

@MainActor
class PhotoManager: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit { PHPhotoLibrary.shared().unregisterChangeObserver(self) }

    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor [weak self] in
            guard let self, let result = self.allAssetsResult,
                  changeInstance.changeDetails(for: result) != nil else { return }
            self.requestAccessAndFetch()
        }
    }
    @Published var authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @Published var libraryRevision = 0
    var isAuthorized: Bool { authorizationStatus == .authorized || authorizationStatus == .limited }
    private var lastStatus: PHAuthorizationStatus?

    func refreshIfAuthorized() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        authorizationStatus = status
        guard status == .authorized || status == .limited else {
            if lastStatus != nil {
                assets = []
                allAssetsResult = nil
                shuffledIndices = []
                currentIndex = 0
                totalPhotos = 0
                lastStatus = nil
                libraryRevision += 1
            }
            return
        }
        if lastStatus != status { requestAccessAndFetch() }
    }

    @Published var assets: [PHAsset] = []
    @Published var accessDenied = false
    @Published var totalPhotos: Int = 0

    private var allAssetsResult: PHFetchResult<PHAsset>?
    private var shuffledIndices: [Int] = []
    private var currentIndex = 0

    func requestAccessAndFetch() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async { [weak self] in
                self?.authorizationStatus = status
                self?.accessDenied = status == .denied || status == .restricted
            }

            guard status == .authorized || status == .limited else { return }

            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let result = PHAsset.fetchAssets(with: .image, options: options)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.allAssetsResult = result
                self.totalPhotos = result.count
                self.shuffledIndices = Array(0..<result.count).shuffled()
                self.currentIndex = 0
                self.assets = []
                self.loadNextBatch()
                self.lastStatus = status
                self.libraryRevision += 1
            }
        }
    }

    func loadNextBatch() {
        guard let allAssetsResult, currentIndex < shuffledIndices.count else { return }

        var batch: [PHAsset] = []

        while currentIndex < shuffledIndices.count && batch.count < 50 {
            let asset = allAssetsResult.object(at: shuffledIndices[currentIndex])
            if !HistoryManager.shared.isRated(asset.localIdentifier) {
                batch.append(asset)
            }
            currentIndex += 1
        }

        assets.append(contentsOf: batch)
    }

    var hasMoreBatches: Bool {
        currentIndex < shuffledIndices.count
    }
}

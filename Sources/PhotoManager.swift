import Photos
import SwiftUI

class PhotoManager: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var accessDenied = false

    func requestAccessAndFetch() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async { [weak self] in
                self?.accessDenied = status == .denied || status == .restricted
            }

            guard status == .authorized || status == .limited else { return }

            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = 50

            let result = PHAsset.fetchAssets(with: .image, options: options)
            var fetchedAssets: [PHAsset] = []
            result.enumerateObjects { asset, _, _ in
                fetchedAssets.append(asset)
            }

            DispatchQueue.main.async { [weak self] in
                self?.assets = fetchedAssets
            }
        }
    }
}

import Photos
import UIKit

/// One completion per request, including timeout, cancellation and iCloud failures.
@MainActor
final class PhotoImageLoader {
    static func image(for asset: PHAsset, size: CGSize = CGSize(width: 300, height: 300),
                      networkAllowed: Bool = false) async -> UIImage? {
        let request = PhotoImageLoader()
        return await withTaskCancellationHandler {
            guard !Task.isCancelled else { return nil }
            return await request.load(asset, size: size, networkAllowed: networkAllowed)
        } onCancel: {
            Task { @MainActor in request.finish(nil) }
        }
    }

    private var continuation: CheckedContinuation<UIImage?, Never>?
    private var requestID: PHImageRequestID?
    private var timeout: Task<Void, Never>?
    private var completed = false

    private func load(_ asset: PHAsset, size: CGSize, networkAllowed: Bool) async -> UIImage? {
        guard !completed else { return nil }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isNetworkAccessAllowed = networkAllowed
            requestID = PHImageManager.default().requestImage(for: asset, targetSize: size,
                contentMode: .aspectFit, options: options) { image, info in
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) == true
                guard !degraded else { return }
                Task { @MainActor in self.finish(image) }
            }
            timeout = Task {
                do { try await Task.sleep(for: .seconds(networkAllowed ? 30 : 8)) }
                catch { return }
                finish(nil)
            }
        }
    }

    private func finish(_ image: UIImage?) {
        guard !completed else { return }
        completed = true
        timeout?.cancel()
        if let requestID { PHImageManager.default().cancelImageRequest(requestID) }
        continuation?.resume(returning: image)
        continuation = nil
        timeout = nil
    }
}

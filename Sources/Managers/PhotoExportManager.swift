import Photos
import UIKit

@MainActor
final class PhotoExportManager {
    enum ExportError: LocalizedError {
        case accessDenied, saveFailed
        var errorDescription: String? {
            switch self {
            case .accessDenied: return "Consenti a GallerIA di aggiungere foto dalla sezione Foto nelle Impostazioni di iOS."
            case .saveFailed: return "La copia non è stata salvata. Controlla lo spazio disponibile e riprova."
            }
        }
    }

    static func saveCopy(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw ExportError.accessDenied }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success { continuation.resume() }
                else { continuation.resume(throwing: error ?? ExportError.saveFailed) }
            }
        }
    }
}

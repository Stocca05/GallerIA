import Photos

/// A single boundary for all destructive actions, revalidated against the live library.
@MainActor
final class PhotoDeletionService {
    static let shared = PhotoDeletionService()

    func delete(_ ids: Set<String>, groups: [[String]], protection: PhotoDecisionStore? = nil) async throws {
        let protection = protection ?? .shared
        if let error = protection.loadError { throw failure(error) }
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw failure("L’accesso alle foto è cambiato. Controlla i permessi e riprova.")
        }
        guard !ids.isEmpty, ids.isDisjoint(with: protection.data.protectedIDs) else {
            throw failure("La selezione contiene ricordi protetti. Rimuovili dalla selezione prima di eliminare.")
        }
        let relevant = groups.filter { !Set($0).isDisjoint(with: ids) }
        let live = PHAsset.fetchAssets(withLocalIdentifiers: Array(Set(relevant.flatMap { $0 }).union(ids)), options: nil)
        var available = Set<String>()
        live.enumerateObjects { asset, _, _ in available.insert(asset.localIdentifier) }
        guard CleanupSelection.preservesEveryGroup(selected: ids, groups: relevant, available: available) else {
            throw failure("Conserva almeno una foto disponibile per ogni gruppo di scatti simili.")
        }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: Array(ids), options: nil)
        var protected = false
        assets.enumerateObjects { asset, _, _ in
            if asset.isFavorite || !asset.canPerform(.delete) { protected = true }
        }
        guard assets.count == ids.count, !protected else {
            throw failure("La libreria è cambiata o contiene preferiti o elementi non eliminabili. Aggiorna la selezione.")
        }
        try await PHPhotoLibrary.shared().performChanges { PHAssetChangeRequest.deleteAssets(assets) }
    }

    private func failure(_ text: String) -> NSError {
        NSError(domain: "GallerIA.PhotoDeletion", code: 1, userInfo: [NSLocalizedDescriptionKey: text])
    }
}

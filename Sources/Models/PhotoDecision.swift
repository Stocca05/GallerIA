import Foundation
import Combine

enum PhotoDecisionReason: String, Codable, CaseIterable, Identifiable {
    case keep, memory, notMyStyle, duplicate, temporary
    var id: Self { self }
    var title: String {
        switch self {
        case .keep: return "Mi piace: da tenere"
        case .memory: return "È un ricordo importante"
        case .notMyStyle: return "Non rispecchia il mio gusto"
        case .duplicate: return "È una copia o uno scatto simile"
        case .temporary: return "Non mi serve più"
        }
    }
    var trainingLabel: Float? {
        switch self {
        case .keep: return 1
        case .notMyStyle: return 0
        case .memory, .duplicate, .temporary: return nil
        }
    }
    var protectsPhoto: Bool { self == .keep || self == .memory }
    static var deletionReasons: [Self] { [.notMyStyle, .duplicate, .temporary] }
}

struct PhotoDecisionData: Codable {
    var protectedIDs: Set<String> = []
    var reasons: [String: PhotoDecisionReason] = [:]
    var deletedCount = 0
}

/// Writes atomically before publishing so a failed save never pretends protection was enabled.
@MainActor
final class PhotoDecisionStore: ObservableObject {
    static let shared = PhotoDecisionStore()
    @Published private(set) var data: PhotoDecisionData
    @Published private(set) var loadError: String?
    private let storageURL: URL

    init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("photo_decisions.json")
        do {
            data = try JSONDecoder().decode(PhotoDecisionData.self, from: Data(contentsOf: self.storageURL))
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile { data = PhotoDecisionData() }
        catch {
            data = PhotoDecisionData()
            loadError = "Le protezioni salvate non sono leggibili. Per sicurezza, l’eliminazione è bloccata."
        }
    }

    func isProtected(_ id: String) -> Bool { data.protectedIDs.contains(id) }

    func setProtection(_ id: String, enabled: Bool) throws {
        var next = data
        if enabled { next.protectedIDs.insert(id) } else { next.protectedIDs.remove(id) }
        try save(next)
    }

    func record(_ ids: Set<String>, reason: PhotoDecisionReason, deleted: Bool = false) throws {
        var next = data
        for id in ids {
            next.reasons[id] = reason
            if reason.protectsPhoto { next.protectedIDs.insert(id) }
        }
        if deleted { next.deletedCount += ids.count }
        try save(next)
    }

    func reset() throws { try save(PhotoDecisionData(), recovering: true) }

    private func save(_ next: PhotoDecisionData, recovering: Bool = false) throws {
        guard loadError == nil || recovering else {
            throw NSError(domain: "GallerIA", code: 1, userInfo: [NSLocalizedDescriptionKey: loadError!])
        }
        try JSONEncoder().encode(next).write(to: storageURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        data = next
        loadError = nil
        NotificationCenter.default.post(name: .init("GallerIAProtectionChanged"), object: nil)
    }
}

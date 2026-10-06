import Foundation

final class EmbeddingCache: @unchecked Sendable {
    static let shared = EmbeddingCache()
    private let queue = DispatchQueue(label: "com.stocca.GallerIA.embeddingCache", qos: .utility)
    private let fileURL: URL
    private var embeddings: [String: [Float]]
    private var isDirty = false
    private var saveWorkItem: DispatchWorkItem?

    private init() {
        fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("embeddings_cache.json")
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([String: [Float]].self, from: data) {
            embeddings = saved
        } else {
            embeddings = [:]
        }
    }

    func getEmbedding(for id: String) -> [Float]? {
        queue.sync { embeddings[id] }
    }

    func saveEmbedding(_ embedding: [Float], for id: String) {
        queue.async { [self] in
            embeddings[id] = embedding
            isDirty = true
            debouncedSave()
        }
    }

    /// Debounce disk writes: wait 2 seconds of inactivity before writing.
    private func debouncedSave() {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [self] in
            guard isDirty else { return }
            do {
                let data = try JSONEncoder().encode(embeddings)
                try data.write(to: fileURL, options: .atomic)
                isDirty = false
            } catch {
                NSLog("EmbeddingCache: failed to save cache: %@", error.localizedDescription)
            }
        }
        saveWorkItem = workItem
        queue.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
}

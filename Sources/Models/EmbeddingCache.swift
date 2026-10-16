import Foundation

final class EmbeddingCache: @unchecked Sendable {
    static let shared = EmbeddingCache()
    private let queue = DispatchQueue(label: "com.stocca.GallerIA.embeddingCache", qos: .utility)
    private let fileURL: URL
    private var embeddings: [String: [Float]]
    private var accessOrder: [String] = []
    private let capacity = 1000
    private var isDirty = false
    private var saveWorkItem: DispatchWorkItem?

    init(storageURL: URL? = nil) {
        fileURL = storageURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("embeddings_cache.json")
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([String: [Float]].self, from: data) {
            embeddings = saved
        } else {
            embeddings = [:]
        }
        accessOrder = Array(embeddings.keys.sorted().suffix(capacity))
        embeddings = embeddings.filter { accessOrder.contains($0.key) }
    }

    func getEmbedding(for id: String) -> [Float]? {
        queue.sync {
            guard let embedding = embeddings[id] else { return nil }
            accessOrder.removeAll { $0 == id }
            accessOrder.append(id)
            return embedding
        }
    }

    func saveEmbedding(_ embedding: [Float], for id: String) {
        guard !embedding.isEmpty, embedding.allSatisfy({ $0.isFinite }) else { return }
        queue.async { [self] in
            embeddings[id] = embedding
            accessOrder.removeAll { $0 == id }
            accessOrder.append(id)
            while accessOrder.count > capacity { embeddings.removeValue(forKey: accessOrder.removeFirst()) }
            isDirty = true
            debouncedSave()
        }
    }

    func clear() throws {
        try queue.sync {
            saveWorkItem?.cancel()
            if FileManager.default.fileExists(atPath: fileURL.path) { try FileManager.default.removeItem(at: fileURL) }
            embeddings.removeAll()
            accessOrder.removeAll()
            isDirty = false
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

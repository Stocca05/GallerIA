import Foundation

final class EmbeddingCache: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.stocca.GallerIA.embeddingCache", qos: .utility)
    private let fileURL: URL
    private var embeddings: [String: [Float]]

    init() {
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
        queue.async {
            self.embeddings[id] = embedding
            do {
                let data = try JSONEncoder().encode(self.embeddings)
                try data.write(to: self.fileURL, options: .atomic)
            } catch {
                NSLog("EmbeddingCache: failed to save cache: %@", error.localizedDescription)
            }
        }
    }
}

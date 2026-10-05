import Foundation

final class HistoryManager: @unchecked Sendable {
    static let shared = HistoryManager()

    private let queue = DispatchQueue(label: "com.stocca.GallerIA.history", qos: .utility)
    private let fileURL: URL
    private var ratedIDs: Set<String>

    private init() {
        fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("rated_history.json")
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(Set<String>.self, from: data) {
            ratedIDs = saved
        } else {
            ratedIDs = []
        }
    }

    func isRated(_ id: String) -> Bool {
        queue.sync { ratedIDs.contains(id) }
    }

    func markAsRated(_ id: String) {
        queue.async {
            if self.ratedIDs.insert(id).inserted {
                self.save()
            }
        }
    }

    func unmarkAsRated(_ id: String) {
        queue.async {
            if self.ratedIDs.remove(id) != nil {
                self.save()
            }
        }
    }

    func reset() {
        queue.async {
            self.ratedIDs.removeAll()
            self.save()
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(self.ratedIDs)
            try data.write(to: self.fileURL, options: .atomic)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
}

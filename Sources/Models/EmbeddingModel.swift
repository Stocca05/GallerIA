import Foundation
import SwiftData

@Model
final class EmbeddingModel {
    @Attribute(.unique) var photoIdentifier: String
    var embeddingData: Data
    var timestamp: Date

    init(photoIdentifier: String, embedding: [Float]) {
        self.photoIdentifier = photoIdentifier
        // Convert Float array to Data for efficient storage
        self.embeddingData = embedding.withUnsafeBufferPointer { Data(buffer: $0) }
        self.timestamp = Date()
    }

    var embedding: [Float] {
        let count = embeddingData.count / MemoryLayout<Float>.size
        var array = [Float](repeating: 0, count: count)
        _ = array.withUnsafeMutableBytes { embeddingData.copyBytes(to: $0) }
        return array
    }
}

import Vision
import CoreGraphics
import Accelerate

final class MLManager: Sendable {
    func extractEmbedding(from cgImage: CGImage) -> [Float]? {
        let request = VNGenerateImageFeaturePrintRequest()
        request.imageCropAndScaleOption = .scaleFill
        let handler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try handler.perform([request])
            guard let observation = request.results?.first as? VNFeaturePrintObservation else {
                return nil
            }

            let floats = observation.data.withUnsafeBytes { ptr in Array(ptr.bindMemory(to: Float.self)) }
            return floats
        } catch {
            return nil
        }
    }

    func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard !a.isEmpty, a.count == b.count else { return 0 }

        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0

        vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))
        vDSP_svesq(a, 1, &normA, vDSP_Length(a.count))
        vDSP_svesq(b, 1, &normB, vDSP_Length(b.count))

        if normA == 0 || normB == 0 { return 0 }
        return dotProduct / (sqrt(normA) * sqrt(normB))
    }

    /// Processes multiple images simultaneously, utilizing all P and E cores of Apple Silicon
    func batchExtractEmbeddings(from images: [String: CGImage]) async -> [String: [Float]] {
        return await withTaskGroup(of: (String, [Float]?).self) { group in
            var results: [String: [Float]] = [:]

            for (id, cgImage) in images {
                group.addTask {
                    let embedding = self.extractEmbedding(from: cgImage)
                    return (id, embedding)
                }
            }

            for await (id, embedding) in group {
                if let embedding = embedding {
                    results[id] = embedding
                }
            }

            return results
        }
    }
}

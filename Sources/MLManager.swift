import Vision
import CoreGraphics

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
}

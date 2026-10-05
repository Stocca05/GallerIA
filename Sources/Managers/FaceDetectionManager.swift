import Vision
import CoreGraphics

class FaceDetectionManager {
    static let shared = FaceDetectionManager()

    private init() {}

    func hasFaces(in cgImage: CGImage) async -> Bool {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            if let results = request.results {
                return !results.isEmpty
            }
        } catch {
            print("Face detection failed: \(error)")
        }

        return false
    }
}

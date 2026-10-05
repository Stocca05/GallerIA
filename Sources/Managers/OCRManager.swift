import Vision
import CoreImage

class OCRManager {
    static let shared = OCRManager()

    private init() {}

    func extractText(from cgImage: CGImage) async -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            guard let observations = request.results else { return "" }

            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            return recognizedStrings.joined(separator: "\n")
        } catch {
            print("OCR Failed: \(error.localizedDescription)")
            return ""
        }
    }
}

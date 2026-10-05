import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

class PhotoEditorManager {
    static let shared = PhotoEditorManager()
    private let context = CIContext()

    private init() {}

    func autoEnhance(image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)

        let filters = ciImage.autoAdjustmentFilters()
        var outputImage = ciImage

        for filter in filters {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            if let result = filter.outputImage {
                outputImage = result
            }
        }

        let vibranceFilter = CIFilter.vibrance()
        vibranceFilter.inputImage = outputImage
        vibranceFilter.amount = 0.5

        if let vibrantOutput = vibranceFilter.outputImage {
            outputImage = vibrantOutput
        }

        guard let finalCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: finalCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    func applyManualAdjustments(image: UIImage, brightness: Float, contrast: Float, saturation: Float) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)

        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.brightness = brightness
        filter.contrast = contrast
        filter.saturation = saturation

        guard let outputImage = filter.outputImage,
              let finalCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: finalCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

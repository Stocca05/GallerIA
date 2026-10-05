import UIKit
import CoreGraphics

class CollageManager {
    static let shared = CollageManager()

    private init() {}

    func createCollage(from images: [UIImage]) -> UIImage? {
        // We only support exactly 4 images for a 2x2 grid collage
        guard images.count >= 4 else { return nil }

        let size = CGSize(width: 1000, height: 1000)
        let imageSize = CGSize(width: 490, height: 490)
        let spacing: CGFloat = 20

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Background
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        let positions: [CGPoint] = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: imageSize.width + spacing, y: 0),
            CGPoint(x: 0, y: imageSize.height + spacing),
            CGPoint(x: imageSize.width + spacing, y: imageSize.height + spacing)
        ]

        for i in 0..<4 {
            let image = images[i]
            let rect = CGRect(origin: positions[i], size: imageSize)

            // Draw rounded rect mask
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 40)
            context.saveGState()
            path.addClip()

            // Draw image filling the rect
            image.draw(in: aspectFillRect(for: image.size, in: rect))
            context.restoreGState()
        }

        let collageImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return collageImage
    }

    private func aspectFillRect(for imageSize: CGSize, in rect: CGRect) -> CGRect {
        let widthRatio = rect.width / imageSize.width
        let heightRatio = rect.height / imageSize.height
        let scale = max(widthRatio, heightRatio)

        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        let x = rect.origin.x + (rect.width - scaledWidth) / 2.0
        let y = rect.origin.y + (rect.height - scaledHeight) / 2.0

        return CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
    }
}

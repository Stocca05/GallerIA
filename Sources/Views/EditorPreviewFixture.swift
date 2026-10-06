#if DEBUG
import UIKit

/// Synthetic, local-only fixture for editor UI tests; excluded from release builds.
enum EditorPreviewFixture {
    static let image: UIImage = {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 800, height: 600), format: format).image { context in
            UIColor(red: 0.16, green: 0.27, blue: 0.24, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 800, height: 600))
            UIColor(red: 0.79, green: 0.93, blue: 0.63, alpha: 1).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 280, y: 90, width: 240, height: 240))
            UIColor(red: 0.10, green: 0.18, blue: 0.14, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 370, width: 800, height: 230))
        }
    }()
}
#endif

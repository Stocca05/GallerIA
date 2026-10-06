import XCTest
import UIKit
@testable import GallerIA

final class GalleryCriteriaTests: XCTestCase {
    func testUntrainedLibraryDoesNotHidePhotosBelowThreshold() {
        let criteria = GalleryCriteria(scope: .suggested, threshold: 0.9, trained: false)
        XCTAssertTrue(criteria.includes(score: 0.5, favorite: false, date: nil))
    }

    func testSuggestionThresholdAndAllScope() {
        var criteria = GalleryCriteria(threshold: 0.8, trained: true)
        XCTAssertFalse(criteria.includes(score: 0.79, favorite: true, date: nil))
        XCTAssertTrue(criteria.includes(score: 0.8, favorite: false, date: nil))
        criteria.scope = .all
        XCTAssertTrue(criteria.includes(score: 0.1, favorite: false, date: nil))
    }

    func testFavoritesIgnoreAffinityButRespectFavoriteFlag() {
        let criteria = GalleryCriteria(scope: .favorites, threshold: 0.9, trained: true)
        XCTAssertTrue(criteria.includes(score: 0.1, favorite: true, date: nil))
        XCTAssertFalse(criteria.includes(score: 1, favorite: false, date: nil))
    }

    func testDateSearchMatchesAllTermsAndHandlesMissingDates() {
        let date = ISO8601DateFormatter().date(from: "2026-10-06T12:00:00Z")!
        var criteria = GalleryCriteria(scope: .all, query: "  OTTOBRE 2026  ")
        XCTAssertTrue(criteria.includes(score: 0, favorite: false, date: date))
        XCTAssertFalse(criteria.includes(score: 0, favorite: false, date: nil))
        criteria.query = "ottobre 2025"
        XCTAssertFalse(criteria.includes(score: 0, favorite: false, date: date))
        criteria.query = "2026-10-06"
        XCTAssertTrue(criteria.includes(score: 0, favorite: false, date: date))
        criteria.query = "   "
        XCTAssertTrue(criteria.includes(score: 0, favorite: false, date: nil))
    }

    func testManualAdjustmentsPreserveImageDimensionsAndSource() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 20), format: format).image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 20))
        }
        let originalData = image.pngData()
        let result = try XCTUnwrap(PhotoEditorManager.shared.applyManualAdjustments(image: image, brightness: 0.2, contrast: 1, saturation: 1))
        XCTAssertEqual(result.cgImage?.width, 40)
        XCTAssertEqual(result.cgImage?.height, 20)
        XCTAssertEqual(image.pngData(), originalData)
        XCTAssertNotEqual(result.pngData(), originalData)
    }
}

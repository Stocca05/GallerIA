import XCTest
@testable import GallerIA

final class RecommendationPolicyTests: XCTestCase {
    func testSingleClassTrainingCannotUnlockDeletionSuggestions() {
        XCTAssertFalse(RecommendationPolicy.canRecommend(positiveCount: 20, negativeCount: 0))
        XCTAssertFalse(RecommendationPolicy.canRecommend(positiveCount: 4, negativeCount: 20))
        XCTAssertTrue(RecommendationPolicy.canRecommend(positiveCount: 5, negativeCount: 5))
    }

    func testFavoritesAndUncertainPhotosAreNeverDeletionSuggestions() {
        XCTAssertFalse(RecommendationPolicy.shouldReviewForDeletion(score: 0.1, threshold: 0.5, favorite: true))
        XCTAssertFalse(RecommendationPolicy.shouldReviewForDeletion(score: 0.5, threshold: 0.9, favorite: false))
        XCTAssertFalse(RecommendationPolicy.shouldReviewForDeletion(score: .nan, threshold: 0.5, favorite: false))
        XCTAssertTrue(RecommendationPolicy.shouldReviewForDeletion(score: 0.2, threshold: 0.5, favorite: false))
    }

    func testRecommendationReadinessRequiresConfirmedBalancedHistoryAndSurvivesReload() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let classifier = AestheticClassifier(storageURL: url)
        for _ in 0..<5 {
            classifier.update(embedding: [1, 0], label: 1)
            classifier.update(embedding: [0, 1], label: 0)
        }
        XCTAssertFalse(classifier.canRecommend, "Pending choices must not unlock suggestions")
        classifier.flushBatch()
        XCTAssertTrue(classifier.canRecommend)
        let restored = AestheticClassifier(storageURL: url)
        XCTAssertTrue(restored.canRecommend)
        XCTAssertGreaterThan(restored.predict(embedding: [1, 0]), restored.predict(embedding: [0, 1]))
        restored.reset()
        XCTAssertFalse(restored.canRecommend)
    }

    func testThresholdsLeaveUncertainPhotosUnclassified() {
        XCTAssertFalse(RecommendationPolicy.shouldKeep(score: 0.5, threshold: 0.2))
        XCTAssertTrue(RecommendationPolicy.shouldKeep(score: 0.8, threshold: 0.5))
        XCTAssertFalse(RecommendationPolicy.shouldReviewForDeletion(score: 0.3, threshold: 0.2, favorite: false))
        XCTAssertFalse(RecommendationPolicy.shouldKeep(score: 0.8, threshold: 0.9))
    }
}

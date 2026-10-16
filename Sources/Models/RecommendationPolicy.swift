import Foundation

enum RecommendationPolicy {
    static func canRecommend(positiveCount: Int, negativeCount: Int) -> Bool {
        positiveCount >= 5 && negativeCount >= 5
    }

    static func shouldKeep(score: Float, threshold: Float) -> Bool {
        score.isFinite && score >= max(0.65, threshold)
    }

    static func shouldReviewForDeletion(score: Float, threshold: Float, favorite: Bool) -> Bool {
        !favorite && score.isFinite && score <= min(0.35, threshold)
    }
}

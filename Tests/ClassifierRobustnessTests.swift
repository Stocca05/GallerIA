import XCTest
@testable import GallerIA

final class ClassifierRobustnessTests: XCTestCase {
    func testScalingFeaturesDoesNotChangePredictions() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let classifier = AestheticClassifier(storageURL: url)
        for _ in 0..<5 {
            classifier.update(embedding: [10000, 0], label: 1)
            classifier.update(embedding: [0, 10000], label: 0)
        }
        classifier.flushBatch()
        XCTAssertEqual(classifier.predict(embedding: [1, 0]), classifier.predict(embedding: [10000, 0]), accuracy: 0.0001)
        XCTAssertGreaterThan(classifier.predict(embedding: [1, 0]), classifier.predict(embedding: [0, 1]))
        XCTAssertEqual(classifier.predict(embedding: [.nan, 0]), 0.5)
        XCTAssertEqual(classifier.predict(embedding: [0, 0]), 0.5)
    }

    func testMismatchedPersistedHistoryIsRejectedWithoutCrashing() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let corrupt = ClassifierData(weights: [0, 0], bias: 0, iterations: 1,
            historyEmbeddings: [[1, 0], [0, 1]], historyLabels: [1])
        try JSONEncoder().encode(corrupt).write(to: url)
        let classifier = AestheticClassifier(storageURL: url)
        XCTAssertFalse(classifier.canRecommend)
        XCTAssertNotNil(classifier.storageError)
        classifier.reset()
        XCTAssertNil(classifier.storageError)
    }

    func testLegacyHistoryMigratesToNormalizedFeatures() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let old = ClassifierData(weights: [1, -1], bias: 0, iterations: 1,
            historyEmbeddings: [[10, 0], [0, 10]], historyLabels: [1, 0])
        try JSONEncoder().encode(old).write(to: url)
        let classifier = AestheticClassifier(storageURL: url)
        XCTAssertNil(classifier.storageError)
        XCTAssertEqual(classifier.totalSamples, 2)
        XCTAssertEqual(classifier.predict(embedding: [1, 0]), classifier.predict(embedding: [100, 0]), accuracy: 0.0001)
        let saved = try JSONDecoder().decode(ClassifierData.self, from: Data(contentsOf: url))
        XCTAssertEqual(saved.featureVersion, 1)
    }
}

import XCTest
@testable import GallerIA

final class GallerIATests: XCTestCase {

    func testInvalidEmbeddingsAreRejected() {
        let classifier = AestheticClassifier(storageURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        classifier.update(embedding: [], label: 1)
        classifier.update(embedding: [.nan, 1], label: 1)
        XCTAssertTrue(classifier.batchEmbeddings.isEmpty)
        classifier.update(embedding: [1, 0], label: 1)
        classifier.update(embedding: [1, 0, 0], label: 0)
        XCTAssertEqual(classifier.batchEmbeddings.count, 1)
    }

    func testPersistAndReset() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let classifier = AestheticClassifier(storageURL: url)
        classifier.update(embedding: [1, 0], label: 1)
        classifier.flushBatch()
        XCTAssertTrue(AestheticClassifier(storageURL: url).isTrained)
        classifier.reset()
        XCTAssertFalse(AestheticClassifier(storageURL: url).isTrained)
    }

    func testUndoBeforeTraining() {
        let classifier = AestheticClassifier(storageURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        classifier.update(embedding: [1, 0], label: 1)
        XCTAssertTrue(classifier.undoLastUpdate())
        XCTAssertFalse(classifier.undoLastUpdate())
        classifier.flushBatch()
        XCTAssertFalse(classifier.isTrained)
    }

    func testCosineSimilarity() {
        let mlManager = MLManager()

        // Exact same vectors should have similarity 1.0
        let a: [Float] = [1.0, 2.0, 3.0]
        let b: [Float] = [1.0, 2.0, 3.0]
        let sim1 = mlManager.cosineSimilarity(a, b)
        XCTAssertEqual(sim1, 1.0, accuracy: 0.0001)

        // Orthogonal vectors should have similarity 0.0
        let x: [Float] = [1.0, 0.0]
        let y: [Float] = [0.0, 1.0]
        let sim2 = mlManager.cosineSimilarity(x, y)
        XCTAssertEqual(sim2, 0.0, accuracy: 0.0001)

        // Opposite vectors should have similarity -1.0
        let p: [Float] = [1.0, 1.0]
        let q: [Float] = [-1.0, -1.0]
        let sim3 = mlManager.cosineSimilarity(p, q)
        XCTAssertEqual(sim3, -1.0, accuracy: 0.0001)
    }

    func testAestheticClassifierInitialization() {
        let classifier = AestheticClassifier(storageURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        XCTAssertFalse(classifier.isTrained)
        XCTAssertEqual(classifier.totalSamples, 0)
        XCTAssertEqual(classifier.iterations, 0)
    }

    func testAestheticClassifierPredictionBeforeTraining() {
        let classifier = AestheticClassifier(storageURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let embedding: [Float] = [0.5, 0.5, 0.5]

        // Before training, predict should return 0.5
        let score = classifier.predict(embedding: embedding)
        XCTAssertEqual(score, 0.5, accuracy: 0.0001)
    }

    func testAestheticClassifierTraining() {
        let classifier = AestheticClassifier(storageURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))

        // Feed 10 good photos and 10 bad photos
        for _ in 0..<10 {
            classifier.update(embedding: [1.0, 0.0], label: 1.0) // Good feature
            classifier.update(embedding: [0.0, 1.0], label: 0.0) // Bad feature
        }

        classifier.flushBatch()

        XCTAssertTrue(classifier.isTrained)
        XCTAssertEqual(classifier.totalSamples, 20)

        let goodScore = classifier.predict(embedding: [1.0, 0.0])
        let badScore = classifier.predict(embedding: [0.0, 1.0])

        XCTAssertGreaterThan(goodScore, badScore)
    }
}

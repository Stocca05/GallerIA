import XCTest
@testable import GallerIA

final class EmbeddingCacheTests: XCTestCase {
    func testCacheEvictsLeastRecentlyUsedFeaturesAndClearRemovesAllData() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let cache = EmbeddingCache(storageURL: url)
        for index in 0..<1000 { cache.saveEmbedding([1, Float(index)], for: "photo-\(index)") }
        XCTAssertNotNil(cache.getEmbedding(for: "photo-0"))
        cache.saveEmbedding([1, 1000], for: "photo-1000")
        XCTAssertNotNil(cache.getEmbedding(for: "photo-0"))
        XCTAssertNil(cache.getEmbedding(for: "photo-1"))
        XCTAssertNotNil(cache.getEmbedding(for: "photo-1000"))
        try cache.clear()
        XCTAssertNil(cache.getEmbedding(for: "photo-0"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
}

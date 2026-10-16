import XCTest
@testable import GallerIA

final class PhotoDecisionTests: XCTestCase {
    func testHousekeepingAndMemoriesDoNotTrainTaste() {
        XCTAssertEqual(PhotoDecisionReason.keep.trainingLabel, 1)
        XCTAssertEqual(PhotoDecisionReason.notMyStyle.trainingLabel, 0)
        for reason in [PhotoDecisionReason.duplicate, .temporary, .memory] { XCTAssertNil(reason.trainingLabel) }
        XCTAssertTrue(PhotoDecisionReason.memory.protectsPhoto)
        XCTAssertTrue(PhotoDecisionReason.keep.protectsPhoto)
        XCTAssertFalse(PhotoDecisionReason.notMyStyle.protectsPhoto)
    }

    @MainActor func testProtectionAndReasonsSurviveReloadAndCanBeRemoved() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = PhotoDecisionStore(storageURL: url)
        XCTAssertNil(store.loadError)
        try store.record(["memory"], reason: .memory)
        try store.record(["copy"], reason: .duplicate, deleted: true)
        let restored = PhotoDecisionStore(storageURL: url)
        XCTAssertTrue(restored.isProtected("memory"))
        XCTAssertFalse(restored.isProtected("copy"))
        XCTAssertEqual(restored.data.reasons["copy"], .duplicate)
        XCTAssertEqual(restored.data.deletedCount, 1)
        try restored.setProtection("memory", enabled: false)
        XCTAssertFalse(PhotoDecisionStore(storageURL: url).isProtected("memory"))
        try restored.reset()
        XCTAssertTrue(restored.data.reasons.isEmpty)
        XCTAssertEqual(restored.data.deletedCount, 0)
    }

    @MainActor func testFailedSaveDoesNotPretendProtectionWasPersisted() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("missing/file.json")
        let store = PhotoDecisionStore(storageURL: url)
        XCTAssertThrowsError(try store.setProtection("photo", enabled: true))
        XCTAssertFalse(store.isProtected("photo"))
    }

    @MainActor func testCorruptProtectionDataFailsClosedUntilExplicitReset() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("corrupt".utf8).write(to: url)
        let store = PhotoDecisionStore(storageURL: url)
        XCTAssertNotNil(store.loadError)
        XCTAssertThrowsError(try store.record(["photo"], reason: .keep))
        try store.reset()
        XCTAssertNil(PhotoDecisionStore(storageURL: url).loadError)
    }

    func testActiveLearningPrioritizesUncertaintyWithRegularExploration() {
        let candidates: [(id: String, score: Float)] = [("certain", 0.95), ("uncertain", 0.51), ("middle", 0.7)]
        XCTAssertEqual(TrainingPriority.orderedIDs(candidates, step: 0), ["uncertain", "middle", "certain"])
        XCTAssertEqual(TrainingPriority.orderedIDs(candidates, step: 4), ["certain", "uncertain", "middle"])
        XCTAssertEqual(TrainingPriority.orderedIDs([("invalid", .nan), ("valid", 0.5)], step: 0), ["valid", "invalid"])
    }

    func testPublicLinksRejectPlaceholderAndNonHTTPSAddresses() {
        XCTAssertNil(ReleaseConfiguration.publicURL(""))
        XCTAssertNil(ReleaseConfiguration.publicURL("http://example.org/privacy"))
        XCTAssertNil(ReleaseConfiguration.publicURL("https://example.com/privacy"))
        XCTAssertNil(ReleaseConfiguration.publicURL("https://test.invalid/privacy"))
        XCTAssertNil(ReleaseConfiguration.publicURL("https://user:password@company.org/privacy"))
        XCTAssertNotNil(ReleaseConfiguration.publicURL("https://company.org/privacy"))
    }
}

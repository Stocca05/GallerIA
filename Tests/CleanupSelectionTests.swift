import XCTest
@testable import GallerIA

final class CleanupSelectionTests: XCTestCase {
    func testCannotSelectLastRemainingPhoto() {
        let groups = [["original", "copy"]]
        XCTAssertTrue(CleanupSelection.canSelect("copy", selected: [], groups: groups))
        XCTAssertFalse(CleanupSelection.canSelect("original", selected: ["copy"], groups: groups))
        XCTAssertFalse(CleanupSelection.preservesEveryGroup(selected: ["original", "copy"], groups: groups))
    }

    func testUserCanChooseWhichPhotoToKeep() {
        let groups = [["recommended", "alternative", "third"]]
        XCTAssertTrue(CleanupSelection.canSelect("recommended", selected: ["third"], groups: groups))
        XCTAssertTrue(CleanupSelection.preservesEveryGroup(selected: ["recommended", "third"], groups: groups))
    }

    func testSuggestionsExcludeAllFavoritesAndKeepers() {
        let groups = [["keeper", "favorite", "copy"], ["keeper2", "favorite2"]]
        let selected = CleanupSelection.suggested(groups: groups, protected: ["favorite", "favorite2"])
        XCTAssertEqual(selected, ["copy"])
        XCTAssertTrue(CleanupSelection.preservesEveryGroup(selected: selected, groups: groups))
    }

    func testOverlappingGroupsCannotBeEntirelySelected() {
        let groups = [["a", "b"], ["b", "c"], ["c", "a"]]
        let suggested = CleanupSelection.suggested(groups: groups, protected: [])
        XCTAssertTrue(CleanupSelection.preservesEveryGroup(selected: suggested, groups: groups))
        XCTAssertFalse(CleanupSelection.canSelect("c", selected: ["b"], groups: groups))
    }

    func testIndependentAssetsAndEmptyGroups() {
        XCTAssertTrue(CleanupSelection.canSelect("screenshot", selected: [], groups: []))
        XCTAssertTrue(CleanupSelection.preservesEveryGroup(selected: ["screenshot"], groups: [[]]))
        XCTAssertEqual(CleanupSelection.suggested(groups: [[], ["only"]], protected: []), [])
    }

    func testKeeperDeletedOutsideAppCannotLeaveGroupUnprotected() {
        XCTAssertFalse(CleanupSelection.preservesEveryGroup(selected: ["copy"],
            groups: [["keeper", "copy"]], available: ["copy"]))
        XCTAssertTrue(CleanupSelection.preservesEveryGroup(selected: ["copy"],
            groups: [["keeper", "copy"]], available: ["keeper", "copy"]))
    }

    func testStaleSelectionIsRevalidatedAgainstNewGroups() {
        let selected: Set<String> = ["a", "b"]
        XCTAssertTrue(CleanupSelection.preservesEveryGroup(selected: selected, groups: [["a", "b", "c"]]))
        XCTAssertFalse(CleanupSelection.preservesEveryGroup(selected: selected, groups: [["a", "b"]]))
    }
}

import Foundation

/// Selection rules shared by the UI and the final deletion validation.
enum CleanupSelection {
    static func canSelect(_ id: String, selected: Set<String>, groups: [[String]]) -> Bool {
        let proposed = selected.union([id])
        return groups.filter { $0.contains(id) }.allSatisfy {
            !Set($0).isSubset(of: proposed)
        }
    }

    static func preservesEveryGroup(selected: Set<String>, groups: [[String]], available: Set<String>? = nil) -> Bool {
        groups.allSatisfy { group in
            let remaining = Set(group).intersection(available ?? Set(group))
            return remaining.isEmpty || !remaining.isSubset(of: selected)
        }
    }

    static func suggested(groups: [[String]], protected: Set<String>) -> Set<String> {
        var result = Set<String>()
        for group in groups {
            // Each group is ordered with its recommended keeper first.
            for id in group.dropFirst() where !protected.contains(id) {
                if canSelect(id, selected: result, groups: groups) { result.insert(id) }
            }
        }
        return result
    }
}

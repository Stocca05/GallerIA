import Foundation

enum TrainingPriority {
    /// Reserve occasional exploration while bringing uncertain examples to the front.
    static func orderedIDs(_ candidates: [(id: String, score: Float)], step: Int) -> [String] {
        guard step % 5 != 4 else { return candidates.map(\.id) }
        return candidates.sorted {
            let lhs = $0.score.isFinite ? abs($0.score - 0.5) : Float.infinity
            let rhs = $1.score.isFinite ? abs($1.score - 0.5) : Float.infinity
            return lhs == rhs ? $0.id < $1.id : lhs < rhs
        }.map(\.id)
    }
}

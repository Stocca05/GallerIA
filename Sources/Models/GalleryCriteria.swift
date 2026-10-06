import Foundation

enum GalleryScope: String, CaseIterable, Identifiable {
    case suggested = "Per te", all = "Tutte", favorites = "Preferite"
    var id: Self { self }
}

enum GalleryOrder: String, CaseIterable, Identifiable {
    case affinity = "Affinità", newest = "Più recenti", oldest = "Meno recenti"
    var id: Self { self }
}

struct GalleryCriteria {
    var scope: GalleryScope = .suggested
    var query = ""
    var threshold: Float = 0.5
    var trained = false

    func includes(score: Float, favorite: Bool, date: Date?) -> Bool {
        if scope == .suggested && trained && score < threshold { return false }
        if scope == .favorites && !favorite { return false }
        let terms = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !terms.isEmpty else { return true }
        guard let date else { return false }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "d MMMM yyyy yyyy-MM-dd"
        let searchable = formatter.string(from: date)
        return terms.allSatisfy { searchable.localizedStandardContains($0) }
    }
}

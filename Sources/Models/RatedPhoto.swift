import Foundation
import SwiftData

@Model
final class RatedPhoto {
    @Attribute(.unique) var photoIdentifier: String
    var timestamp: Date

    init(photoIdentifier: String) {
        self.photoIdentifier = photoIdentifier
        self.timestamp = Date()
    }
}

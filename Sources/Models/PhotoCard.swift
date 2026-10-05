import SwiftUI
import Photos

struct PhotoCard: Identifiable, Equatable {
    let id: String
    let asset: PHAsset
    var image: UIImage?
    var embedding: [Float]?
    var score: Float = 0.5
}

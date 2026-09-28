import SwiftUI
import Photos
import UIKit

struct TrashGameView: View {
    @State var uglyAssets: [ScoredAsset]
    let classifier: AestheticClassifier

    @Environment(\.dismiss) var dismiss
    @State private var isDeleting = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                if uglyAssets.isEmpty {
                    Text("Pulizia terminata!")
                        .font(.title.bold())
                } else {
                    let current = uglyAssets.first!

                    Text("Scorri verso destra per eliminare, sinistra per salvare")
                        .multilineTextAlignment(.center)

                    CardView(image: current.image, score: current.score, isCleanup: true) { swipedRight in
                        guard !isDeleting else { return }

                        let haptic = UINotificationFeedbackGenerator()
                        haptic.notificationOccurred(swipedRight ? .warning : .success)

                        if swipedRight {
                            isDeleting = true
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.deleteAssets([current.asset] as NSArray)
                            }) { success, _ in
                                DispatchQueue.main.async {
                                    if success {
                                        classifier.update(embedding: current.embedding, label: 0.0)
                                    }
                                    uglyAssets.removeFirst()
                                    isDeleting = false
                                }
                            }
                        } else {
                            classifier.update(embedding: current.embedding, label: 1.0)
                            uglyAssets.removeFirst()
                        }
                    }
                    .id(current.id)
                    .allowsHitTesting(!isDeleting)
                }

                Button("Chiudi") {
                    dismiss()
                }
            }
            .foregroundColor(.white)
            .padding()
        }
    }
}

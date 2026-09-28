import SwiftUI
import Photos
import UIKit

struct TrashGameView: View {
    @State var uglyAssets: [ScoredAsset]
    let classifier: AestheticClassifier

    @Environment(\.dismiss) var dismiss
    @State private var isDeleting = false
    @State private var assetsToDelete: [PHAsset] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Text("GallerIA\nCLEANUP")
                .font(.system(size: 60, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.05))
                .multilineTextAlignment(.center)
                .rotationEffect(.degrees(-15))

            VStack(spacing: 24) {
                if uglyAssets.isEmpty {
                    if !assetsToDelete.isEmpty {
                        Text("Hai scartato \(assetsToDelete.count) foto")
                            .font(.title.bold())
                        
                        Button {
                            isDeleting = true
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
                            }) { success, _ in
                                DispatchQueue.main.async {
                                    if success {
                                        assetsToDelete.removeAll()
                                    }
                                    isDeleting = false
                                }
                            }
                        } label: {
                            Text("Svuota Cestino")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .disabled(isDeleting)
                    } else {
                        Text("Pulizia terminata!")
                            .font(.title.bold())
                    }
                } else {
                    let current = uglyAssets.first!

                    Text("Scorri verso destra per eliminare, sinistra per salvare")
                        .multilineTextAlignment(.center)

                    CardView(image: current.image, score: current.score, isCleanup: true) { swipedRight in
                        let haptic = UINotificationFeedbackGenerator()
                        haptic.notificationOccurred(swipedRight ? .warning : .success)

                        if swipedRight {
                            assetsToDelete.append(current.asset)
                            classifier.update(embedding: current.embedding, label: 0.0)
                            uglyAssets.removeFirst()
                        } else {
                            classifier.update(embedding: current.embedding, label: 1.0)
                            uglyAssets.removeFirst()
                        }
                    }
                    .id(current.id)
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

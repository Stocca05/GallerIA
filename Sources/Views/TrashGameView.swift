import SwiftUI
import Photos
import UIKit

struct TrashGameView: View {
    @State var uglyAssets: [ScoredAsset]
    let classifier: AestheticClassifier

    @Environment(\.dismiss) var dismiss
    @State private var isDeleting = false
    @State private var assetsToDelete: [PHAsset] = []

    // Stack for undo
    @State private var lastSwipedAsset: ScoredAsset?
    @State private var lastSwipedWasDelete: Bool?

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
                                        SoundManager.shared.playDelete()
                                        HapticSymphonyManager.shared.playSuccessRipple()
                                    }
                                    isDeleting = false
                                }
                            }
                        } label: {
                            if isDeleting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Svuota Cestino")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red, in: Capsule())
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

                        lastSwipedAsset = current
                        lastSwipedWasDelete = swipedRight

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

                Spacer()

                HStack {
                    Button("Chiudi") {
                        dismiss()
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: Capsule())

                    Spacer()

                    if let _ = lastSwipedAsset {
                        Button {
                            undoLastAction()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Annulla")
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundColor(.cyan)
                    }
                }
                .padding(.horizontal)
            }
            .foregroundColor(.white)
            .padding(.top)
            .padding(.bottom, 20)
        }
    }

    private func undoLastAction() {
        guard let lastAsset = lastSwipedAsset, let wasDelete = lastSwipedWasDelete else { return }

        // Put it back in the queue at the front
        uglyAssets.insert(lastAsset, at: 0)

        // Reverse the arrays
        if wasDelete {
            assetsToDelete.removeAll { $0.localIdentifier == lastAsset.asset.localIdentifier }
        }

        // Clear undo state
        lastSwipedAsset = nil
        lastSwipedWasDelete = nil

        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
    }
}

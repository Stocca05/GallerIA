import SwiftUI
import Photos
import UIKit

struct ScoredAsset: Identifiable {
    let id = UUID()
    let asset: PHAsset
    let image: UIImage
    let score: Float
    let embedding: [Float]
}

struct GalleryView: View {
    let classifier: AestheticClassifier
    let mlManager: MLManager

    @Environment(\.dismiss) private var dismiss
    @AppStorage("aestheticThreshold") private var aestheticThreshold: Double = 0.5

    @State private var scoredAssets: [ScoredAsset] = []
    @State private var showTrashGame = false

    var body: some View {
        let goodAssets = scoredAssets.filter { $0.score >= Float(aestheticThreshold) }

        NavigationStack {
            Group {
                if scoredAssets.isEmpty {
                    VStack {
                        ProgressView()
                        Text("Analisi estetica neurale in corso...")
                            .font(.headline)
                            .foregroundColor(.purple)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                                ForEach(goodAssets) { scoredAsset in
                                    let image = scoredAsset.image
                                    let score = scoredAsset.score

                                    GalleryCellView(image: image, score: score)
                                }
                            }
                            .padding()
                        }

                        Button("Minigioco Pulizia (\(scoredAssets.filter { $0.score < Float(aestheticThreshold) }.count) foto da scartare)") {
                            showTrashGame = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.red, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("La tua Estetica")
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showTrashGame) {
            TrashGameView(
                uglyAssets: scoredAssets.filter { $0.score < Float(aestheticThreshold) },
                classifier: classifier
            )
        }
        .task {
            let loadingTask = Task.detached(priority: .userInitiated) { [classifier, mlManager] () -> [ScoredAsset] in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.fetchLimit = 100
                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

                let options = PHImageRequestOptions()
                options.isSynchronous = false
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .exact

                let imageManager = PHImageManager.default()
                var results: [ScoredAsset] = []

                for index in 0..<assets.count {
                    guard !Task.isCancelled else { break }

                    let image = await fetchImage(for: assets.object(at: index), with: imageManager, options: options)
                    guard !Task.isCancelled else { break }
                    guard let image,
                          let cgImage = image.cgImage,
                          let embedding = mlManager.extractEmbedding(from: cgImage) else { continue }

                    results.append(ScoredAsset(
                        asset: assets.object(at: index),
                        image: image,
                        score: classifier.predict(embedding: embedding),
                        embedding: embedding
                    ))
                }

                return results.sorted { $0.score > $1.score }
            }

            let loadedAssets = await withTaskCancellationHandler {
                await loadingTask.value
            } onCancel: {
                loadingTask.cancel()
            }

            guard !Task.isCancelled else { return }
            scoredAssets = loadedAssets
        }
    }
}

private func fetchImage(for asset: PHAsset, with manager: PHImageManager, options: PHImageRequestOptions) async -> UIImage? {
    await withCheckedContinuation { continuation in
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 300, height: 300),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            continuation.resume(returning: image)
        }
    }
}

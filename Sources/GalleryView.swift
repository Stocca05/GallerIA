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

    @State private var scoredAssets: [ScoredAsset] = []
    @State private var showTrashGame = false

    var body: some View {
        let goodAssets = scoredAssets.filter { $0.score >= 0.5 }

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

                                    ShareLink(
                                        item: Image(uiImage: image),
                                        preview: SharePreview("Scelto dall'IA", image: Image(uiImage: image))
                                    ) {
                                        Color.clear
                                            .aspectRatio(1, contentMode: .fit)
                                            .overlay {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                            }
                                            .clipped()
                                            .overlay(alignment: .bottomTrailing) {
                                                HStack(spacing: 4) {
                                                    if score >= 0.8 {
                                                        Image(systemName: "star.fill")
                                                            .foregroundColor(.yellow)
                                                    }
                                                    Text("\(Int(score * 100))%")
                                                        .foregroundColor(.white)
                                                }
                                                .font(.caption2.bold())
                                                .padding(4)
                                                .background(.black.opacity(0.65), in: Capsule())
                                                .padding(4)
                                            }
                                    }
                                }
                            }
                            .padding()
                        }

                        Button("Minigioco Pulizia (\(scoredAssets.filter { $0.score < 0.5 }.count) foto brutte)") {
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
                uglyAssets: scoredAssets.filter { $0.score < 0.5 },
                classifier: classifier
            )
        }
        .task {
            let loadingTask = Task.detached(priority: .userInitiated) { [classifier, mlManager] in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.fetchLimit = 100
                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

                let options = PHImageRequestOptions()
                options.isSynchronous = true
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .exact

                let imageManager = PHImageManager.default()
                var results: [ScoredAsset] = []

                for index in 0..<assets.count {
                    guard !Task.isCancelled else { break }

                    autoreleasepool {
                        var thumbnail: UIImage?
                        imageManager.requestImage(
                            for: assets.object(at: index),
                            targetSize: CGSize(width: 300, height: 300),
                            contentMode: .aspectFit,
                            options: options
                        ) { image, _ in
                            thumbnail = image
                        }

                        guard let image = thumbnail,
                              let cgImage = image.cgImage,
                              let embedding = mlManager.extractEmbedding(from: cgImage) else { return }

                        results.append(ScoredAsset(
                            asset: assets.object(at: index),
                            image: image,
                            score: classifier.predict(embedding: embedding),
                            embedding: embedding
                        ))
                    }
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

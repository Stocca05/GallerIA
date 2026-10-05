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

    @State private var isLoading = true
    @State private var scoredAssets: [ScoredAsset] = []
    @State private var showTrashGame = false
    @State private var selectedAsset: ScoredAsset?
    @State private var loadingProgress: Int = 0
    @State private var loadingTotal: Int = 0
    @State private var generatedCollage: UIImage?
    @State private var showMap = false
    var body: some View {
        let goodAssets = scoredAssets.filter { $0.score >= Float(aestheticThreshold) }
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Prepariamo la tua raccolta…")
                            .font(.headline)
                            .foregroundColor(.purple)
                        if loadingTotal > 0 {
                            Text("\(loadingProgress) / \(loadingTotal)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .monospacedDigit()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if goodAssets.isEmpty {
                    ContentUnavailableView("Nessuna foto da mostrare", systemImage: "photo.stack", description: Text("Prova ad aggiungere foto accessibili o ad affinare le tue preferenze dalla scheda Seleziona."))
                } else {
                    VStack {
                        ScrollView {
                            WaterfallGrid(goodAssets, id: \.id, columns: 3, spacing: 8) { scoredAsset in
                                Button {
                                    selectedAsset = scoredAsset
                                } label: {
                                    GalleryCellView(image: scoredAsset.image, score: scoredAsset.score)
                                }
                            }
                            .padding()

                            if goodAssets.count >= 4 {
                                Button {
                                    generateCollage(from: goodAssets)
                                } label: {
                                    HStack {
                                        Image(systemName: "square.grid.2x2.fill")
                                        Text("Crea un collage")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 16))
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                            }

                            Button {
                                showMap = true
                            } label: {
                                HStack {
                                    Image(systemName: "map.fill")
                                    Text("Riscopri i luoghi")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                        }


                    }
                }
            }
            .background(GalleryStyle.background.ignoresSafeArea())
            .navigationTitle("La tua raccolta")
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
        .sheet(item: $selectedAsset) { asset in
            PhotoDetailView(image: asset.image, score: asset.score)
        }
        .task {
            let loadingTask = Task.detached(priority: .userInitiated) { [classifier, mlManager] () -> [ScoredAsset] in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.fetchLimit = 500
                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

                await MainActor.run {
                    self.loadingTotal = min(150, assets.count)
                }

                var results: [ScoredAsset] = []
                var processedCount = 0

                for index in 0..<assets.count {
                    guard !Task.isCancelled else { break }
                    guard processedCount < 150 else { break }

                    let asset = assets.object(at: index)



                    let image = await fetchImage(for: asset)
                    guard !Task.isCancelled else { break }
                    guard let image,
                          let cgImage = image.cgImage,
                          let embedding = mlManager.extractEmbedding(from: cgImage) else {
                        continue
                    }

                    results.append(ScoredAsset(
                        asset: asset,
                        image: image,
                        score: await MainActor.run { classifier.predict(embedding: embedding) },
                        embedding: embedding
                    ))
                    processedCount += 1

                    let currentCount = processedCount
                    await MainActor.run { self.loadingProgress = currentCount }



                    await Task.yield()
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
            isLoading = false
            HapticSymphonyManager.shared.playScanningSymphony()
        }
        .sheet(isPresented: Binding(get: { generatedCollage != nil }, set: { if !$0 { generatedCollage = nil } })) {
            if let generatedCollage { CollagePreviewView(image: generatedCollage) }
        }
        .fullScreenCover(isPresented: $showMap) {
            MapMasterpieceView(goodAssets: scoredAssets.filter { $0.score >= Float(aestheticThreshold) })
        }
    }

    private func generateCollage(from assets: [ScoredAsset]) {
        let top4 = Array(assets.prefix(4)).map { $0.image }
        Task.detached(priority: .userInitiated) {
            let collage = CollageManager.shared.createCollage(from: top4)
            await MainActor.run {
                if let collage = collage {
                    self.generatedCollage = collage
                    HapticSymphonyManager.shared.playSuccessRipple()
                }
            }
        }
    }
}

struct CollagePreviewView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()

                ShareLink(item: Image(uiImage: image), preview: SharePreview("Collage Capolavori", image: Image(uiImage: image))) {
                    Text("Condividi Collage")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cyan, in: Capsule())
                        .foregroundColor(.black)
                }
                .padding()
            }
            .background(GalleryStyle.background.ignoresSafeArea())
            .navigationTitle("Collage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }
}

/// Safe image fetcher: uses `fastFormat` to get a single callback (no double-resume risk).
private func fetchImage(for asset: PHAsset) async -> UIImage? {
    await withCheckedContinuation { continuation in
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 300, height: 300),
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            // fastFormat guarantees a single callback, safe for continuation
            continuation.resume(returning: image)
        }
    }
}

import SwiftUI
import Photos

struct ScoredAsset: Identifiable {
    var id: String { asset.localIdentifier }
    let asset: PHAsset
    let image: UIImage
    let score: Float
    let embedding: [Float]
}

struct GalleryView: View {
    let classifier: AestheticClassifier
    let mlManager: MLManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("aestheticThreshold") private var threshold = 0.5
    @State private var isLoading = true
    @State private var scoredAssets: [ScoredAsset] = []
    @State private var selectedAsset: ScoredAsset?
    @State private var processed = 0
    @State private var total = 0
    @State private var skipped = 0
    @State private var revision = 0
    @State private var scanID = UUID()
    @State private var query = ""
    @State private var scope = GalleryScope.suggested
    @State private var order = GalleryOrder.affinity
    @State private var generatedCollage: UIImage?
    @State private var isMakingCollage = false
    @State private var collageError: String?
    @State private var showMap = false

    private var visible: [ScoredAsset] {
        let criteria = GalleryCriteria(scope: scope, query: query, threshold: Float(threshold), trained: classifier.isTrained)
        return scoredAssets.filter { criteria.includes(score: $0.score, favorite: $0.asset.isFavorite, date: $0.asset.creationDate) }
            .sorted {
                switch order {
                case .affinity:
                    if $0.score != $1.score { return $0.score > $1.score }
                case .newest:
                    if $0.asset.creationDate != $1.asset.creationDate { return ($0.asset.creationDate ?? .distantPast) > ($1.asset.creationDate ?? .distantPast) }
                case .oldest:
                    if $0.asset.creationDate != $1.asset.creationDate { return ($0.asset.creationDate ?? .distantFuture) < ($1.asset.creationDate ?? .distantFuture) }
                }
                return $0.id < $1.id
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Mostra", selection: $scope) {
                        ForEach(GalleryScope.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    HStack {
                        Text("\(visible.count) foto").font(.headline)
                        Spacer()
                        Menu {
                            Picker("Ordina", selection: $order) {
                                ForEach(GalleryOrder.allCases) { Text($0.rawValue).tag($0) }
                            }
                        } label: { Label(order.rawValue, systemImage: "arrow.up.arrow.down").font(.caption) }
                    }
                    if isLoading {
                        ProgressView(value: Double(processed), total: Double(max(total, 1))) {
                            Text("Analisi: \(processed) di \(total)").font(.caption)
                        }.tint(GalleryStyle.accent)
                    }
                    if !classifier.isTrained {
                        Text("Inizia a scegliere nella scheda Seleziona per rendere personale la raccolta. Per ora mostriamo tutte le foto analizzate.")
                            .font(.footnote).foregroundStyle(GalleryStyle.secondary)
                    }
                    if visible.isEmpty && !isLoading {
                        ContentUnavailableView {
                            Label("Nessuna corrispondenza", systemImage: "photo.on.rectangle")
                        } description: { Text("Prova Tutte, cancella la ricerca o aggiorna la raccolta. Le foto disponibili solo su iCloud possono essere escluse dall’analisi locale.") }
                        actions: {
                            Button("Azzera filtri") { query = ""; scope = .all }
                            Button("Aggiorna") { revision += 1 }
                        }
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                            ForEach(visible) { item in
                                Button { selectedAsset = item } label: {
                                    GalleryCellView(image: item.image, score: item.score)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }.accessibilityLabel("Apri foto del \(item.asset.creationDate?.formatted(date: .abbreviated, time: .omitted) ?? "data sconosciuta")")
                            }
                        }
                    }
                    if visible.count >= 4 {
                        Button { makeCollage() } label: {
                            if isMakingCollage { ProgressView().tint(GalleryStyle.background) }
                            else { Label("Collage delle prime 4 foto", systemImage: "square.grid.2x2") }
                        }.buttonStyle(PrimaryButton()).disabled(isMakingCollage)
                    }
                    if visible.contains(where: { $0.asset.location != nil }) {
                        Button { showMap = true } label: { Label("Riscopri i luoghi", systemImage: "map") }
                    }
                    Text("Fino a 150 foto recenti, analizzate sul dispositivo. \(skipped) non disponibili o non analizzabili.")
                        .font(.caption).foregroundStyle(GalleryStyle.secondary)
                }.padding(20).frame(maxWidth: 900).frame(maxWidth: .infinity)
            }
            .background(GalleryStyle.background)
            .navigationTitle("La tua raccolta")
            .searchable(text: $query, prompt: "Cerca per data: ottobre, 2026…")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Chiudi") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button { revision += 1 } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Aggiorna raccolta") }
            }
            .task(id: revision) { await load() }
            .sheet(item: $selectedAsset) { PhotoDetailView(image: $0.image, score: $0.score, asset: $0.asset) }
            .sheet(isPresented: Binding(get: { generatedCollage != nil }, set: { if !$0 { generatedCollage = nil } })) {
                if let generatedCollage { CollagePreviewView(image: generatedCollage) }
            }
            .fullScreenCover(isPresented: $showMap) { MapMasterpieceView(goodAssets: visible) }
            .alert("Collage non disponibile", isPresented: Binding(get: { collageError != nil }, set: { if !$0 { collageError = nil } })) {
                Button("OK") { collageError = nil }
            } message: { Text(collageError ?? "Riprova.") }
        }.tint(GalleryStyle.accent).preferredColorScheme(.dark)
    }

    private func load() async {
        let token = UUID()
        scanID = token
        isLoading = true
        processed = 0
        skipped = 0
        scoredAssets = []
        let worker = Task.detached(priority: .utility) {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = 150
            let assets = PHAsset.fetchAssets(with: .image, options: options)
            await MainActor.run { if scanID == token { total = assets.count } }
            for index in 0..<assets.count {
                guard !Task.isCancelled else { return }
                let asset = assets.object(at: index)
                let image = await PhotoImageLoader.image(for: asset)
                guard !Task.isCancelled else { return }
                if let image, let cgImage = image.cgImage, let embedding = mlManager.extractEmbedding(from: cgImage) {
                    await MainActor.run {
                        guard scanID == token, !Task.isCancelled else { return }
                        scoredAssets.append(ScoredAsset(asset: asset, image: image, score: classifier.predict(embedding: embedding), embedding: embedding))
                    }
                } else { await MainActor.run { if scanID == token { skipped += 1 } } }
                await MainActor.run { if scanID == token { processed = index + 1 } }
            }
        }
        await withTaskCancellationHandler { await worker.value } onCancel: { worker.cancel() }
        guard !Task.isCancelled else { return }
        isLoading = false
    }

    private func makeCollage() {
        guard !isMakingCollage else { return }
        let selection = Array(visible.prefix(4))
        isMakingCollage = true
        Task {
            defer { isMakingCollage = false }
            var images: [UIImage] = []
            for item in selection {
                guard let image = await PhotoImageLoader.image(for: item.asset, size: CGSize(width: 1200, height: 1200), networkAllowed: true) else {
                    collageError = "Una delle quattro foto non è disponibile. Controlla la connessione e riprova."; return
                }
                images.append(image)
            }
            generatedCollage = CollageManager.shared.createCollage(from: images)
            if generatedCollage == nil { collageError = "Impossibile creare il collage." }
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

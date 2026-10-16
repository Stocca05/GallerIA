import SwiftUI
import Photos

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var badAssets: [ScoredAsset] = []
    @Published var goodAssets: [ScoredAsset] = []
    @Published var isScanning = false

    let classifier: AestheticClassifier
    let mlManager: MLManager
    private var scanTask: Task<Void, Never>?

    init(classifier: AestheticClassifier, mlManager: MLManager) {
        self.classifier = classifier
        self.mlManager = mlManager
    }

    func cancelScan(clear: Bool = false) {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        if clear { goodAssets = []; badAssets = [] }
    }

    func removeReviewed(_ id: String) {
        goodAssets.removeAll { $0.id == id }
        badAssets.removeAll { $0.id == id }
    }

    func startScan(threshold: Double) {
        guard scanTask == nil else { return }
        isScanning = true

        scanTask = Task {
            let loadingTask = Task.detached(priority: .userInitiated) { [classifier, mlManager] () -> [ScoredAsset] in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.fetchLimit = 200 // Increased for better gallery view
                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

                var results: [ScoredAsset] = []
                var processedCount = 0

                for index in 0..<assets.count {
                    guard !Task.isCancelled else { break }
                    guard processedCount < 150 else { break }

                    let asset = assets.object(at: index)



                    if let image = await PhotoImageLoader.image(for: asset),
                       let cgImage = image.cgImage,
                       let embedding = mlManager.extractEmbedding(from: cgImage) {

                        let score = await MainActor.run { classifier.predict(embedding: embedding) }
                        results.append(ScoredAsset(asset: asset, image: image, score: score, embedding: embedding))
                        processedCount += 1

                        await Task.yield()
                    }
                }
                return results.sorted { $0.score > $1.score }
            }

            let loadedAssets = await withTaskCancellationHandler { await loadingTask.value }
                onCancel: { loadingTask.cancel() }
            guard !Task.isCancelled else { return }

            let candidates = loadedAssets.filter { !HistoryManager.shared.isRated($0.id) && !PhotoDecisionStore.shared.isProtected($0.id) }
            self.goodAssets = classifier.canRecommend ? candidates.filter { RecommendationPolicy.shouldKeep(score: $0.score, threshold: Float(threshold)) } : []
            self.badAssets = classifier.canRecommend ? candidates.filter { RecommendationPolicy.shouldReviewForDeletion(score: $0.score, threshold: Float(threshold), favorite: $0.asset.isFavorite) }.sorted { $0.score < $1.score } : []
            self.isScanning = false
            self.scanTask = nil
        }
    }
}

struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel
    @ObservedObject var cleanupManager: CleanupManager
    @ObservedObject var photoManager: PhotoManager
    var onTrain: () -> Void
    var onFeedback: ([ScoredAsset], PhotoDecisionReason, Bool) throws -> Void
    @ObservedObject private var decisions = PhotoDecisionStore.shared
    @State private var recommendationKind: RecommendationKind?
    @AppStorage("aestheticThreshold") private var threshold = 0.5
    @State private var selectedCleanup: CleanupType?
    @State private var showGallery = false
    @State private var showPro = false
    @EnvironmentObject var proManager: ProManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Label("GallerIA", systemImage: "square.stack.3d.up")
                        .font(.headline)
                    Spacer()
                    Button { showPro = true } label: {
                        Text(proManager.isPro ? "PRO ATTIVO" : "SCOPRI PRO")
                            .font(.caption2.bold()).tracking(1)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(GalleryStyle.accent.opacity(0.12), in: Capsule())
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Fai spazio\\na ciò che ami.".replacingOccurrences(of: "\\n", with: "\n"))
                        .font(.system(.largeTitle, design: .serif).weight(.medium))
                    Text("I tuoi ricordi meritano una bella selezione.")
                        .foregroundStyle(GalleryStyle.secondary)
                }
                if photoManager.isAuthorized {
                    libraryOverview
                    selectionCard
                    recommendationSection
                    cleanupSection
                    highlights
                } else {
                    permissionCard
                }
                Label("Le immagini vengono analizzate sul dispositivo", systemImage: "lock.shield")
                    .font(.caption).foregroundStyle(GalleryStyle.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
            }.padding(24).frame(maxWidth: 720).frame(maxWidth: .infinity)
        }
        .background(GalleryStyle.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPro) { ProView() }
        .sheet(item: $recommendationKind) { kind in
            RecommendationReviewView(viewModel: viewModel, kind: kind, groups: cleanupManager.duplicates.map { $0.assets.map(\.localIdentifier) }) { items, reason, deleted in
                try onFeedback(items, reason, deleted)
                for item in items { viewModel.removeReviewed(item.id) }
            }
        }
        .sheet(item: $selectedCleanup) { CleanupDetailView(cleanupManager: cleanupManager, type: $0) }
        .fullScreenCover(isPresented: $showGallery) { GalleryView(classifier: viewModel.classifier, mlManager: viewModel.mlManager) }
        .task(id: photoManager.libraryRevision) {
            if photoManager.isAuthorized && photoManager.libraryRevision > 0 {
                viewModel.cancelScan()
                cleanupManager.cancelScan()
                scan()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("GallerIAPreferencesChanged"))) { _ in
            if photoManager.isAuthorized { viewModel.cancelScan(); viewModel.startScan(threshold: threshold) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("GallerIAProtectionChanged"))) { _ in
            viewModel.goodAssets.removeAll { decisions.isProtected($0.id) }
            viewModel.badAssets.removeAll { decisions.isProtected($0.id) }
        }
        .refreshable {
            if photoManager.isAuthorized {
                viewModel.cancelScan()
                cleanupManager.cancelScan()
                photoManager.requestAccessAndFetch()
            }
        }
        .onChange(of: threshold) { _, _ in
            if photoManager.isAuthorized { viewModel.cancelScan(); viewModel.startScan(threshold: threshold) }
        }
        .onChange(of: photoManager.authorizationStatus) { _, status in
            if status != .authorized && status != .limited {
                viewModel.cancelScan(clear: true)
                cleanupManager.clearResults()
                recommendationKind = nil
                selectedCleanup = nil
                showGallery = false
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { viewModel.cancelScan(); cleanupManager.cancelScan() }
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "photo.badge.plus").font(.largeTitle).foregroundStyle(GalleryStyle.accent)
            Text("La tua selezione comincia qui").font(.title2.bold())
            Text("Scegli alcune foto oppure tutta la libreria. Puoi cambiare l’accesso in qualsiasi momento.")
                .foregroundStyle(GalleryStyle.secondary)
            Button(photoManager.accessDenied || photoManager.authorizationStatus == .denied ? "Apri le impostazioni" : "Scegli le tue foto") {
                if photoManager.authorizationStatus == .denied || photoManager.authorizationStatus == .restricted {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                } else { photoManager.requestAccessAndFetch() }
            }.buttonStyle(PrimaryButton())
        }.galleryPanel()
    }

    private var libraryOverview: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(photoManager.totalPhotos.formatted()).font(.system(size: 32, weight: .medium)).monospacedDigit()
                Text("foto accessibili").font(.caption).foregroundStyle(GalleryStyle.secondary)
            }
            Spacer()
            Image(systemName: "photo.stack").font(.largeTitle).foregroundStyle(GalleryStyle.accent)
        }.galleryPanel()
        .overlay(alignment: .topTrailing) {
            if photoManager.authorizationStatus == .limited {
                Text("ACCESSO LIMITATO").font(.system(size: 9, weight: .bold)).tracking(1)
                    .foregroundStyle(GalleryStyle.secondary).padding(14)
            }
        }
    }

    private var selectionCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("IL TUO OCCHIO, LA TUA SELEZIONE", systemImage: "sparkles")
                .font(.caption2.bold()).tracking(1)
            Text("Belle per te.\\nÈ questo che conta.".replacingOccurrences(of: "\\n", with: "\n"))
                .font(.system(size: 29, weight: .medium, design: .serif))
            Text("Indica le foto che ti piacciono. GallerIA impara a riconoscere il tuo stile, una scelta alla volta.")
                .font(.subheadline).foregroundStyle(GalleryStyle.background.opacity(0.75))
            Button(action: onTrain) {
                HStack { Text("Affina la tua selezione"); Spacer(); Image(systemName: "arrow.up.right") }
                    .font(.headline).padding(16)
                    .background(GalleryStyle.background, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(GalleryStyle.accent)
            }
        }.padding(24).foregroundStyle(GalleryStyle.background)
            .background(GalleryStyle.accent, in: RoundedRectangle(cornerRadius: 26))
    }

    private var cleanupSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text("Un po’ di spazio in più").font(.title3.bold()); Spacer(); if cleanupManager.isScanning { ProgressView() } }
            Text("Rivedi prima di eliminare. La scelta resta tua.")
                .font(.subheadline).foregroundStyle(GalleryStyle.secondary)
            if cleanupManager.isScanning {
                VStack(alignment: .leading, spacing: 12) {
                    ProgressView(value: Double(cleanupManager.processed), total: Double(max(1, cleanupManager.total)))
                    HStack {
                        Text("\(cleanupManager.processed) / \(cleanupManager.total) foto").monospacedDigit()
                        Spacer()
                        Button("Interrompi") { cleanupManager.cancelScan() }
                    }.font(.caption)
                }.galleryPanel()
            } else {
                HStack {
                    if let date = cleanupManager.lastScan {
                        Text("Ultima analisi: \(date.formatted(date: .omitted, time: .shortened))")
                    }
                    Spacer()
                    Button("Analizza di nuovo") { cleanupManager.startCleanupScan() }
                }.font(.caption).foregroundStyle(GalleryStyle.secondary)
            }
            if let message = cleanupManager.statusMessage {
                Text(message).font(.caption).foregroundStyle(GalleryStyle.secondary)
            }
            VStack(spacing: 0) {
                cleanupRow("Foto simili", subtitle: "Gruppi da confrontare", icon: "square.on.square", count: cleanupManager.duplicates.count, type: .duplicates)
                Divider().overlay(.white.opacity(0.06))
                cleanupRow("Screenshot", subtitle: "Appunti che puoi lasciare andare", icon: "viewfinder", count: cleanupManager.screenshots.count, type: .screenshots)
                Divider().overlay(.white.opacity(0.06))
                cleanupRow("Video recenti", subtitle: "Rivedi i tuoi ultimi filmati", icon: "video", count: cleanupManager.largeVideos.count, type: .largeVideos)
            }.padding(.horizontal, 18).background(GalleryStyle.surface, in: RoundedRectangle(cornerRadius: 24))
            Text("Analisi locale: fino a 500 foto recenti, 100 screenshot e 100 video. Nessun download automatico da iCloud.")
                .font(.caption2).foregroundStyle(GalleryStyle.secondary)
        }
    }

    private func cleanupRow(_ title: String, subtitle: String, icon: String, count: Int, type: CleanupType) -> some View {
        Button {
            if proManager.isPro { selectedCleanup = type } else { showPro = true }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.title3).foregroundStyle(GalleryStyle.accent).frame(width: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(GalleryStyle.secondary)
                }
                Spacer()
                Text(cleanupManager.isScanning ? "—" : count.formatted()).monospacedDigit().foregroundStyle(GalleryStyle.secondary)
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(GalleryStyle.secondary)
            }.padding(.vertical, 20).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("I consigli per te").font(.title3.bold())
            if let error = decisions.loadError { Text(error).font(.footnote).foregroundStyle(.orange) }
            if !viewModel.classifier.canRecommend {
                Text("Scegli almeno 5 foto che ti piacciono e 5 che non fanno per te nella scheda Seleziona. Poi potrai confermare o correggere i consigli per migliorare il modello.")
                    .font(.subheadline).foregroundStyle(GalleryStyle.secondary)
            }
            ForEach(RecommendationKind.allCases) { kind in
                Button { recommendationKind = kind } label: {
                    HStack {
                        Label(kind.rawValue, systemImage: kind == .keep ? "heart" : "trash")
                        Spacer()
                        if viewModel.isScanning { ProgressView() }
                        else { Text((kind == .keep ? viewModel.goodAssets.count : viewModel.badAssets.count).formatted()) }
                        Image(systemName: "chevron.right")
                    }.font(.subheadline).padding(18)
                        .background(GalleryStyle.surface, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain).disabled(!viewModel.classifier.canRecommend)
            }
            Text("I consigli riflettono il tuo gusto. Solo le tue scelte confermate insegnano al modello; i preferiti sono esclusi dalle proposte di eliminazione.")
                .font(.caption).foregroundStyle(GalleryStyle.secondary)
            if decisions.data.deletedCount > 0 {
                Label("\(decisions.data.deletedCount) foto riordinate con i consigli", systemImage: "checkmark.seal")
                    .font(.caption).foregroundStyle(GalleryStyle.accent)
            }
        }
    }

    private var highlights: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Da riscoprire").font(.title3.bold())
                Spacer()
                Button("Apri raccolta") { showGallery = true }.font(.subheadline)
            }
            if viewModel.isScanning {
                ProgressView("Cerchiamo i tuoi prossimi preferiti…").font(.subheadline).padding(.vertical)
            } else if !viewModel.classifier.isTrained {
                Text("La raccolta diventa personale dopo le tue prime scelte. Inizia da Seleziona.")
                    .foregroundStyle(GalleryStyle.secondary).font(.subheadline).galleryPanel()
            } else if viewModel.goodAssets.isEmpty {
                Text("Ancora nessuna corrispondenza. Aggiungi qualche preferenza per affinare i suggerimenti.")
                    .foregroundStyle(GalleryStyle.secondary).font(.subheadline)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.goodAssets.prefix(8)) { item in
                            Button { showGallery = true } label: {
                                Image(uiImage: item.image).resizable().scaledToFill()
                                    .frame(width: 150, height: 190).clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }.accessibilityLabel("Apri la raccolta suggerita")
                        }
                    }
                }
            }
        }
    }

    private func scan() {
        viewModel.startScan(threshold: threshold)
        cleanupManager.startCleanupScan()
    }
}

import SwiftUI
import Photos

enum CleanupType: Identifiable {
    case duplicates, screenshots, largeVideos
    var id: Self { self }
}

struct CleanupDetailView: View {
    @ObservedObject var cleanupManager: CleanupManager
    let type: CleanupType
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAssets: Set<String> = []
    @State private var isDeleting = false
    @State private var confirmDelete = false
    @State private var deletionError: String?
    @State private var previewAsset: AssetPreview?
    @State private var selectionMessage: String?

    private var title: String {
        switch type {
        case .duplicates: return "Foto simili"
        case .screenshots: return "Screenshot"
        case .largeVideos: return "Video recenti"
        }
    }
    private var assets: [PHAsset] {
        switch type {
        case .duplicates: return cleanupManager.duplicates.flatMap(\.assets)
        case .screenshots: return cleanupManager.screenshots
        case .largeVideos: return cleanupManager.largeVideos
        }
    }
    private var groups: [[String]] {
        cleanupManager.duplicates.map { $0.assets.map(\.localIdentifier) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if cleanupManager.isScanning && type == .duplicates {
                        ProgressView(value: Double(cleanupManager.processed), total: Double(max(1, cleanupManager.total))) {
                            Text("Analisi: \(cleanupManager.processed) di \(cleanupManager.total)")
                        }.galleryPanel()
                    }
                    if assets.isEmpty {
                        ContentUnavailableView(cleanupManager.isScanning ? "Cerchiamo nella tua libreria" : "Niente da riordinare qui",
                            systemImage: "checkmark.seal", description: Text(cleanupManager.isScanning
                                ? "I gruppi compariranno al termine dell’analisi."
                                : "Nessun elemento trovato tra i contenuti analizzati. Le foto su iCloud potrebbero non essere disponibili."))
                    } else {
                        selectionHeader
                        if type == .duplicates {
                            ForEach(cleanupManager.duplicates) { group in
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        Text("\(group.assets.count) foto simili").font(.headline)
                                        Spacer()
                                        Text("Conservane almeno una").font(.caption).foregroundStyle(GalleryStyle.secondary)
                                    }
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(alignment: .top, spacing: 12) {
                                            ForEach(group.assets, id: \.localIdentifier) { asset in
                                                assetCard(asset, keeper: asset.localIdentifier == group.original.localIdentifier)
                                            }
                                        }
                                    }
                                }.galleryPanel()
                            }
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 14)], spacing: 18) {
                                ForEach(assets, id: \.localIdentifier) { assetCard($0) }
                            }
                        }
                    }
                    if let message = cleanupManager.statusMessage {
                        Text(message).font(.footnote).foregroundStyle(GalleryStyle.secondary)
                    }
                }.padding(20)
            }
            .background(GalleryStyle.background)
            .safeAreaInset(edge: .bottom) {
                if !selectedAssets.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(selectedAssets.count) selezionati").font(.headline)
                            Text("Confermerai prima di eliminare").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) { confirmDelete = true } label: {
                            if isDeleting { ProgressView() }
                            else { Label("Elimina", systemImage: "trash") }
                        }.buttonStyle(.borderedProminent).tint(.red).disabled(isDeleting)
                    }.padding().background(.regularMaterial)
                }
            }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Chiudi") { dismiss() }.disabled(isDeleting) }
            }
            .interactiveDismissDisabled(isDeleting)
            .confirmationDialog("Eliminare \(selectedAssets.count) elementi dalla libreria?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Elimina dalla libreria", role: .destructive) { deleteSelected() }
                Button("Annulla", role: .cancel) { }
            } message: { Text("Gli elementi saranno spostati in Eliminati di recente nell’app Foto. La modifica si applica anche alla libreria iCloud, se attiva.") }
            .alert("Controlla la selezione", isPresented: Binding(get: { deletionError != nil }, set: { if !$0 { deletionError = nil } })) {
                Button("OK") { deletionError = nil }
            } message: { Text(deletionError ?? "Riprova.") }
            .sheet(item: $previewAsset) { CleanupPreviewView(asset: $0.asset) }
            .onChange(of: assets.map(\.localIdentifier)) { _, ids in
                selectedAssets.formIntersection(Set(ids))
            }
        }.tint(GalleryStyle.accent).preferredColorScheme(.dark)
    }

    private var selectionHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(type == .duplicates
                 ? "Confronta le immagini prima di scegliere. Il suggerimento da conservare privilegia preferiti e risoluzione."
                 : "Apri un’anteprima e seleziona solo ciò che non ti serve più.")
                .font(.subheadline).foregroundStyle(GalleryStyle.secondary)
            HStack {
                if type == .duplicates {
                    Button("Seleziona suggerite") {
                        let protected = Set(assets.filter(\.isFavorite).map(\.localIdentifier))
                        selectedAssets = CleanupSelection.suggested(groups: groups, protected: protected)
                        selectionMessage = "Preferiti esclusi. Controlla le foto selezionate prima di procedere."
                    }.disabled(cleanupManager.isScanning)
                }
                Spacer()
                Button("Deseleziona tutto") { selectedAssets = []; selectionMessage = nil }
                    .disabled(selectedAssets.isEmpty)
            }.font(.caption.bold()).disabled(isDeleting)
            if let selectionMessage {
                Text(selectionMessage).font(.caption).foregroundStyle(GalleryStyle.accent)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
    }

    private func assetCard(_ asset: PHAsset, keeper: Bool = false) -> some View {
        let selected = selectedAssets.contains(asset.localIdentifier)
        return VStack(alignment: .leading, spacing: 8) {
            Button { previewAsset = AssetPreview(asset: asset) } label: {
                ThumbnailView(asset: asset, size: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .topLeading) {
                        if asset.isFavorite {
                            Image(systemName: "heart.fill").font(.caption).padding(7)
                                .background(.regularMaterial, in: Circle()).padding(6)
                        }
                    }
            }.accessibilityLabel("Apri anteprima")
            if keeper { Label("Da conservare", systemImage: "sparkles").font(.caption2).foregroundStyle(GalleryStyle.accent) }
            if asset.mediaType == .video {
                Text(Duration.seconds(asset.duration).formatted(.time(pattern: .minuteSecond)))
                    .font(.caption).monospacedDigit().foregroundStyle(.secondary)
            } else {
                Text("\(asset.pixelWidth) × \(asset.pixelHeight)").font(.caption2).foregroundStyle(.secondary)
            }
            Button {
                if selected { selectedAssets.remove(asset.localIdentifier) }
                else if CleanupSelection.canSelect(asset.localIdentifier, selected: selectedAssets, groups: groups) {
                    selectedAssets.insert(asset.localIdentifier)
                    selectionMessage = nil
                } else { selectionMessage = "Conserva almeno una foto per ogni gruppo di immagini simili." }
            } label: {
                Label(selected ? "Selezionata" : "Seleziona", systemImage: selected ? "checkmark.circle.fill" : "circle")
                    .font(.caption.bold()).frame(maxWidth: .infinity, minHeight: 44)
                    .background(selected ? GalleryStyle.accent.opacity(0.16) : GalleryStyle.surface, in: RoundedRectangle(cornerRadius: 12))
            }.accessibilityValue(selected ? "Selezionata per l’eliminazione" : "Non selezionata")
        }.frame(width: 140).disabled(isDeleting)
    }

    private func deleteSelected() {
        guard !isDeleting, !selectedAssets.isEmpty else { return }
        let ids = selectedAssets.intersection(Set(assets.map(\.localIdentifier)))
        guard !ids.isEmpty else { selectedAssets = []; return }
        let relevantGroups = groups.filter { !Set($0).isDisjoint(with: ids) }
        let liveAssets = PHAsset.fetchAssets(withLocalIdentifiers: Array(Set(relevantGroups.flatMap { $0 }).union(ids)), options: nil)
        var available = Set<String>()
        liveAssets.enumerateObjects { asset, _, _ in available.insert(asset.localIdentifier) }
        guard CleanupSelection.preservesEveryGroup(selected: ids, groups: relevantGroups, available: available) else {
            deletionError = "Conserva almeno una foto per ogni gruppo. La libreria non è stata modificata."; return
        }
        let toDelete = PHAsset.fetchAssets(withLocalIdentifiers: Array(ids), options: nil)
        guard toDelete.count == ids.count else {
            deletionError = "La libreria è cambiata. Aggiorna l’analisi e controlla nuovamente la selezione."; return
        }
        isDeleting = true
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(toDelete)
        } completionHandler: { success, error in
            Task { @MainActor in
                isDeleting = false
                if success {
                    selectedAssets = []
                    selectionMessage = nil
                    cleanupManager.removeDeleted(ids)
                } else { deletionError = error?.localizedDescription ?? "Operazione annullata. Nessuna foto eliminata." }
            }
        }
    }
}

private struct AssetPreview: Identifiable {
    let asset: PHAsset
    var id: String { asset.localIdentifier }
}

private struct CleanupPreviewView: View {
    let asset: PHAsset
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var loading = true
    @State private var retry = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image {
                    Image(uiImage: image).resizable().scaledToFit()
                    if asset.mediaType == .video {
                        Text("Anteprima del video · \(Duration.seconds(asset.duration).formatted(.time(pattern: .minuteSecond)))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let date = asset.creationDate { Text(date, format: .dateTime.day().month(.wide).year()).font(.subheadline) }
                } else if loading { ProgressView("Caricamento anteprima…") }
                else {
                    ContentUnavailableView {
                        Label("Anteprima non disponibile", systemImage: "icloud.slash")
                    } description: { Text("Controlla la connessione per le foto su iCloud.") }
                    actions: { Button("Riprova") { retry += 1 } }
                }
            }.padding().frame(maxWidth: .infinity, maxHeight: .infinity).background(GalleryStyle.background)
                .navigationTitle("Controlla prima di scegliere").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Chiudi") { dismiss() } } }
                .task(id: retry) {
                    loading = true
                    image = await PhotoImageLoader.image(for: asset, size: CGSize(width: 1600, height: 1600), networkAllowed: true)
                    loading = false
                }
        }.preferredColorScheme(.dark)
    }
}

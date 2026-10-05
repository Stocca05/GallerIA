import SwiftUI
import Photos

enum CleanupType: Identifiable {
    case duplicates
    case screenshots
    case largeVideos

    var id: Self { self }
}

struct CleanupDetailView: View {
    @ObservedObject var cleanupManager: CleanupManager
    let type: CleanupType

    @Environment(\.dismiss) var dismiss
    @State private var selectedAssets: Set<String> = []
    @State private var isDeleting = false
    @State private var confirmDelete = false
    @State private var deletionError: String?

    var title: String {
        switch type {
        case .duplicates: return "Foto simili"
        case .screenshots: return "Screenshot"
        case .largeVideos: return "Video recenti"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    if type == .duplicates {
                        duplicatesGrid
                    } else {
                        standardGrid(assets: type == .screenshots ? cleanupManager.screenshots : cleanupManager.largeVideos)
                            .padding(.bottom, 110)
                    }
                }

                // Bottom Delete Bar
                if !selectedAssets.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Text("\(selectedAssets.count) selezionati")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button {
                                confirmDelete = true
                            } label: {
                                if isDeleting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(String(localized: "common.delete"))
                                        .bold()
                                }
                            }
                            .disabled(isDeleting)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.red, in: Capsule())
                        }
                        .padding()
                        .glassmorphism(cornerRadius: 24, borderOpacity: 0.2)
                        .padding()
                    }
                }
            }
            .confirmationDialog("Eliminare \(selectedAssets.count) elementi dalla libreria?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Elimina dalla libreria", role: .destructive) { deleteSelected() }
                Button("Annulla", role: .cancel) { }
            } message: { Text("Gli elementi saranno spostati in Eliminati di recente nell’app Foto.") }
            .alert("Eliminazione non completata", isPresented: Binding(get: { deletionError != nil }, set: { if !$0 { deletionError = nil } })) {
                Button("OK") { deletionError = nil }
            } message: { Text(deletionError ?? "Riprova.") }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.close")) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Grids

    private var duplicatesGrid: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(cleanupManager.duplicates) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gruppo Simile")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(group.assets, id: \.localIdentifier) { asset in
                                selectableThumbnail(for: asset)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
    }

    private func standardGrid(assets: [PHAsset]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 2)], spacing: 2) {
            ForEach(assets, id: \.localIdentifier) { asset in
                selectableThumbnail(for: asset)
            }
        }
    }

    private func selectableThumbnail(for asset: PHAsset) -> some View {
        let isSelected = selectedAssets.contains(asset.localIdentifier)
        return ZStack(alignment: .bottomTrailing) {
            ThumbnailView(asset: asset, size: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .background(Circle().fill(Color.white))
                    .padding(4)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .padding(4)
            }
        }
        .onTapGesture {
            guard !isDeleting else { return }
            SoundManager.shared.playSuccess() // Light tap sound
            if isSelected {
                selectedAssets.remove(asset.localIdentifier)
            } else {
                selectedAssets.insert(asset.localIdentifier)
            }
        }
    }

    // MARK: - Actions

    private func deleteSelected() {
        isDeleting = true
        var toDelete: [PHAsset] = []

        let allAssets = cleanupManager.duplicates.flatMap { $0.assets } + cleanupManager.screenshots + cleanupManager.largeVideos

        for id in selectedAssets {
            if let asset = allAssets.first(where: { $0.localIdentifier == id }) {
                toDelete.append(asset)
            }
        }

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(toDelete as NSArray)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                isDeleting = false
                if success {
                    SoundManager.shared.playDelete()
                    selectedAssets.removeAll()
                    cleanupManager.duplicates.removeAll { $0.assets.contains { toDelete.contains($0) } }
                    cleanupManager.screenshots.removeAll { toDelete.contains($0) }
                    cleanupManager.largeVideos.removeAll { toDelete.contains($0) }
                    cleanupManager.startCleanupScan()
                } else {
                    deletionError = error?.localizedDescription ?? "Operazione annullata. Nessuna modifica applicata."
                }
            }
        }
    }
}

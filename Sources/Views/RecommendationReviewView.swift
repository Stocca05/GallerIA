import SwiftUI
import Photos

enum RecommendationKind: String, CaseIterable, Identifiable {
    case keep = "Foto consigliate da tenere"
    case delete = "Foto consigliate da eliminare"
    var id: Self { self }
}

struct RecommendationReviewView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let kind: RecommendationKind
    let groups: [[String]]
    let onFeedback: ([ScoredAsset], PhotoDecisionReason, Bool) throws -> Void
    @ObservedObject private var decisions = PhotoDecisionStore.shared
    @State private var deletionReason = PhotoDecisionReason.notMyStyle
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = []
    @State private var preview: ScoredAsset?
    @State private var confirming = false
    @State private var deleting = false
    @State private var errorMessage: String?
    @State private var resultMessage: String?

    private var items: [ScoredAsset] { (kind == .keep ? viewModel.goodAssets : viewModel.badAssets).filter { !decisions.isProtected($0.id) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(kind == .keep
                        ? "Conferma le foto da tenere oppure correggi il consiglio. Ogni scelta aggiorna le tue preferenze."
                        : "Un’affinità bassa non significa che una foto sia inutile. Apri l’anteprima, scegli cosa eliminare oppure indica Da tenere.")
                        .font(.subheadline).foregroundStyle(GalleryStyle.secondary)
                    if kind == .delete {
                        Picker("Perché vuoi eliminarle?", selection: $deletionReason) {
                            ForEach(PhotoDecisionReason.deletionReasons) { Text($0.title).tag($0) }
                        }.pickerStyle(.menu).disabled(deleting)
                        Text("Solo ‘Non rispecchia il mio gusto’ modifica le preferenze estetiche. Eliminare una copia o un appunto non significa che la foto non ti piaccia.")
                            .font(.caption).foregroundStyle(GalleryStyle.secondary)
                    }
                    if viewModel.isScanning { ProgressView("Aggiornamento consigli…") }
                    if items.isEmpty && !viewModel.isScanning {
                        ContentUnavailableView("Nessun consiglio da rivedere", systemImage: "checkmark.seal",
                            description: Text("Continua a valutare le foto in Seleziona. Le immagini incerte non vengono proposte per l’eliminazione."))
                    }
                    if let resultMessage { Text(resultMessage).font(.subheadline).foregroundStyle(GalleryStyle.accent) }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 14)], spacing: 20) {
                        ForEach(items) { item in
                            VStack(spacing: 10) {
                                Button { preview = item } label: {
                                    Image(uiImage: item.image).resizable().scaledToFill()
                                        .frame(height: 170).frame(maxWidth: .infinity).clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }.accessibilityLabel("Apri anteprima della foto")
                                Text("Affinità con il tuo gusto: \(Int(item.score * 100))%")
                                    .font(.caption2).foregroundStyle(GalleryStyle.secondary)
                                Button("Da tenere", systemImage: "heart") { review(item, reason: .keep) }
                                    .buttonStyle(.bordered).tint(GalleryStyle.accent)
                                Button("Proteggi ricordo", systemImage: "lock.shield") { review(item, reason: .memory) }.font(.caption)
                                if kind == .keep {
                                    Button("Non fa per me") { review(item, reason: .notMyStyle) }.font(.caption)
                                } else {
                                    Button {
                                        if selected.contains(item.id) { selected.remove(item.id) }
                                        else if CleanupSelection.canSelect(item.id, selected: selected, groups: groups) {
                                            selected.insert(item.id)
                                        } else { errorMessage = "Conserva almeno una foto per ogni gruppo di immagini simili." }
                                    } label: {
                                        Label(selected.contains(item.id) ? "Selezionata" : "Seleziona", systemImage: selected.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    }.font(.caption).accessibilityValue(selected.contains(item.id) ? "Selezionata per l’eliminazione" : "Non selezionata")
                                }
                            }.padding(10).background(GalleryStyle.surface, in: RoundedRectangle(cornerRadius: 20))
                        }
                    }.disabled(deleting)
                }.padding(20)
            }
            .background(GalleryStyle.background)
            .navigationTitle(kind == .keep ? "Da tenere" : "Da eliminare").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Chiudi") { dismiss() }.disabled(deleting) } }
            .safeAreaInset(edge: .bottom) {
                if !selected.isEmpty {
                    HStack {
                        Button("Deseleziona tutto") { selected = [] }.font(.caption)
                        Spacer()
                        Button(role: .destructive) { confirming = true } label: {
                            if deleting { ProgressView() }
                            else { Label("Elimina \(selected.count) foto", systemImage: "trash") }
                        }.buttonStyle(.borderedProminent).tint(.red)
                    }.padding().background(.regularMaterial).disabled(deleting)
                }
            }
            .interactiveDismissDisabled(deleting)
            .confirmationDialog("Eliminare \(selected.count) foto dalla libreria?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Elimina dalla libreria Foto", role: .destructive) { deleteSelected() }
                Button("Annulla", role: .cancel) { }
            } message: {
                Text("Saranno eliminate dalla libreria Foto e da iCloud, se attivo, e spostate in Eliminati di recente. La scelta verrà salvata solo a operazione riuscita, con il motivo indicato.")
            }
            .alert("Operazione non completata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "Riprova.") }
            .sheet(item: $preview) { PhotoDetailView(image: $0.image, score: $0.score, asset: $0.asset) }
            .onChange(of: items.map(\.id)) { _, ids in
                if !deleting { selected.formIntersection(Set(ids)) }
            }
        }.tint(GalleryStyle.accent).preferredColorScheme(.dark)
    }

    private func review(_ item: ScoredAsset, reason: PhotoDecisionReason) {
        guard !deleting, items.contains(where: { $0.id == item.id }) else { return }
        do {
            try onFeedback([item], reason, false)
            selected.remove(item.id)
            resultMessage = reason.protectsPhoto
                ? "Foto protetta: non sarà proposta per l’eliminazione. Gestisci le protezioni in Impostazioni."
                : "Preferenza aggiornata. La foto resta nella libreria."
        } catch { errorMessage = "Scelta non salvata: \(error.localizedDescription)" }
    }

    private func deleteSelected() {
        guard !deleting, !selected.isEmpty else { return }
        let batch = items.filter { selected.contains($0.id) }
        let ids = Set(batch.map(\.id))
        guard ids == selected else {
            errorMessage = "I consigli sono cambiati. Controlla nuovamente la selezione."; return
        }
        let reason = deletionReason
        deleting = true
        Task {
            defer { deleting = false }
            do {
                try await PhotoDeletionService.shared.delete(ids, groups: groups)
            } catch {
                errorMessage = "Nessuna foto eliminata: \(error.localizedDescription)"; return
            }
            selected = []
            do {
                try onFeedback(batch, reason, true)
                resultMessage = "\(batch.count) foto spostate in Eliminati di recente. Scelte salvate."
            } catch {
                errorMessage = "Le foto sono state eliminate, ma non è stato possibile salvare le preferenze: \(error.localizedDescription)"
            }
            NotificationCenter.default.post(name: .init("GallerIALibraryChanged"), object: nil)
        }
    }
}

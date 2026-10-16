import SwiftUI
import Photos

struct ProtectedPhotosView: View {
    @ObservedObject private var decisions = PhotoDecisionStore.shared
    @State private var assets: [PHAsset] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Text("I ricordi protetti sono esclusi dai consigli e da tutte le eliminazioni in GallerIA. La protezione non modifica i preferiti nell’app Foto.")
                    .font(.subheadline)
                if let error = decisions.loadError { Text(error).foregroundStyle(.orange) }
            }
            Section("\(decisions.data.protectedIDs.count) ricordi protetti") {
                ForEach(assets, id: \.localIdentifier) { asset in
                    HStack {
                        ThumbnailView(asset: asset, size: 64).frame(width: 64, height: 64).clipped().cornerRadius(10)
                        VStack(alignment: .leading) {
                            if let date = asset.creationDate { Text(date, format: .dateTime.day().month().year()) }
                            Text("\(asset.pixelWidth) × \(asset.pixelHeight)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Rimuovi protezione", systemImage: "lock.open") {
                            do { try decisions.setProtection(asset.localIdentifier, enabled: false) }
                            catch { errorMessage = error.localizedDescription }
                        }.labelStyle(.iconOnly).buttonStyle(.borderless)
                    }
                }
                if assets.isEmpty {
                    Text("Proteggi un ricordo dal dettaglio di una foto, dai consigli o dal confronto tra scatti simili.")
                        .foregroundStyle(.secondary)
                }
            }
            if assets.count < decisions.data.protectedIDs.count {
                Text("Alcuni ricordi non sono accessibili con i permessi attuali o non sono più nella libreria. Le loro protezioni restano salvate.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }.navigationTitle("Ricordi protetti")
            .task(id: decisions.data.protectedIDs) { load() }
            .alert("Protezione non modificata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "Riprova.") }
    }

    private func load() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else { assets = []; return }
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: Array(decisions.data.protectedIDs), options: options)
        assets = fetched.objects(at: IndexSet(integersIn: 0..<fetched.count))
    }
}

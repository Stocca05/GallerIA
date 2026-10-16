import SwiftUI
import Photos

struct SimilarPhotoComparisonView: View {
    let group: DuplicateGroup
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var decisions = PhotoDecisionStore.shared
    @State private var leftID = ""
    @State private var rightID = ""
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Confronta i dettagli e proteggi lo scatto che vuoi conservare. Nessuna foto viene eliminata da questa schermata.")
                        .font(.subheadline).foregroundStyle(GalleryStyle.secondary)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 14) { comparisonSide(selection: $leftID); comparisonSide(selection: $rightID) }
                        VStack(spacing: 20) { comparisonSide(selection: $leftID); comparisonSide(selection: $rightID) }
                    }
                    if let message { Text(message).font(.footnote).foregroundStyle(GalleryStyle.accent) }
                }.padding(20)
            }.background(GalleryStyle.background)
                .navigationTitle("Confronta gli scatti").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Chiudi") { dismiss() } } }
                .onAppear {
                    leftID = group.assets.first?.localIdentifier ?? ""
                    rightID = group.assets.dropFirst().first?.localIdentifier ?? leftID
                }
        }.preferredColorScheme(.dark)
    }

    private func comparisonSide(selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Scatto", selection: selection) {
                ForEach(Array(group.assets.enumerated()), id: \.element.localIdentifier) { index, asset in
                    Text("Scatto \(index + 1)").tag(asset.localIdentifier)
                }
            }.pickerStyle(.menu)
            if let asset = group.assets.first(where: { $0.localIdentifier == selection.wrappedValue }) {
                ComparisonImage(asset: asset)
                Text("\(asset.pixelWidth) × \(asset.pixelHeight)").font(.caption).monospacedDigit()
                if let date = asset.creationDate { Text(date, format: .dateTime.day().month().hour().minute()).font(.caption) }
                if asset.isFavorite { Label("Preferito in Foto", systemImage: "heart.fill").font(.caption) }
                Button {
                    do {
                        try decisions.setProtection(asset.localIdentifier, enabled: true)
                        message = "Scatto protetto. Potrai rimuovere la protezione dalle Impostazioni."
                    } catch { message = "Protezione non salvata: \(error.localizedDescription)" }
                } label: {
                    Label(decisions.isProtected(asset.localIdentifier) ? "Protetto" : "Conserva questo", systemImage: "lock.shield")
                }.buttonStyle(.bordered).disabled(decisions.isProtected(asset.localIdentifier))
            }
        }.frame(minWidth: 140, maxWidth: .infinity, alignment: .leading)
    }
}

private struct ComparisonImage: View {
    let asset: PHAsset
    @State private var image: UIImage?
    @State private var loading = true
    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Anteprima dello scatto") }
            else if loading { ProgressView("Caricamento…") }
            else { Label("Foto non disponibile", systemImage: "icloud.slash").font(.caption) }
        }.frame(maxWidth: .infinity, minHeight: 180)
            .task(id: asset.localIdentifier) {
                image = nil; loading = true
                let loaded = await PhotoImageLoader.image(for: asset, size: CGSize(width: 1800, height: 1800), networkAllowed: true)
                guard !Task.isCancelled else { return }
                image = loaded; loading = false
            }
    }
}

import SwiftUI
import Photos

struct PhotoDetailView: View {
    @State var image: UIImage
    let score: Float
    var asset: PHAsset? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var original: UIImage?
    @State private var loading = true
    @State private var isEnhancing = false
    @State private var isEnhanced = false
    @State private var showManualEditor = false
    @State private var showOCR = false
    @State private var errorMessage: String?
    @State private var retry = 0
    @State private var ready = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Image(uiImage: image).resizable().scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 480)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                    if loading { ProgressView("Caricamento dell’immagine per modifica e condivisione…").font(.caption) }
                    if !loading && !ready {
                        Text("È disponibile solo la miniatura. Controlla la connessione per caricare la foto da iCloud.")
                            .font(.subheadline).foregroundStyle(GalleryStyle.secondary)
                        Button("Riprova a caricare") { retry += 1 }
                    }
                    if let date = asset?.creationDate {
                        Text(date, format: .dateTime.day().month(.wide).year()).font(.title3.weight(.medium))
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { Text("Affinità con il tuo gusto"); Spacer(); Text(score, format: .percent.precision(.fractionLength(0))).bold() }
                        ProgressView(value: Double(score)).tint(GalleryStyle.accent)
                        Text("Un suggerimento basato sulle tue scelte, non un giudizio sulla qualità della foto.")
                            .font(.caption).foregroundStyle(GalleryStyle.secondary)
                    }.galleryPanel()
                    VStack(spacing: 12) {
                        Button {
                            if isEnhanced, let original { image = original; isEnhanced = false }
                            else { enhance() }
                        } label: {
                            if isEnhancing { ProgressView() }
                            else { Label(isEnhanced ? "Ripristina immagine" : "Regolazione automatica", systemImage: "wand.and.stars") }
                        }.buttonStyle(.bordered).frame(maxWidth: .infinity)
                        HStack {
                            Button { showManualEditor = true } label: { Label("Regola e salva", systemImage: "slider.horizontal.3") }
                            Spacer()
                            Button { showOCR = true } label: { Label("Leggi testo", systemImage: "text.viewfinder") }
                        }.font(.subheadline)
                    }.disabled(!ready || isEnhancing)
                    Text("Immagine ottimizzata fino a 2400 pixel per lato. Le modifiche si salvano come nuova copia dall’editor.")
                        .font(.caption).foregroundStyle(GalleryStyle.secondary)
                }.padding(22).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }.background(GalleryStyle.background)
                .navigationTitle("La tua foto").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Chiudi") { dismiss() } }
                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(item: Image(uiImage: image), preview: SharePreview("La mia foto", image: Image(uiImage: image))) {
                            Label("Condividi", systemImage: "square.and.arrow.up")
                        }.disabled(!ready || isEnhancing)
                    }
                }
                .sheet(isPresented: $showManualEditor) { PhotoEditorView(image: image) }
                .sheet(isPresented: $showOCR) { OCRView(image: image) }
                .task(id: retry) {
                    loading = true
                    if let asset {
                        if let loaded = await PhotoImageLoader.image(for: asset, size: CGSize(width: 2400, height: 2400), networkAllowed: true), !Task.isCancelled {
                            image = loaded; original = loaded; ready = true
                        }
                    } else { original = image; ready = true }
                    loading = false
                }
                .alert("Regolazione non riuscita", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                    Button("OK") { errorMessage = nil }
                } message: { Text(errorMessage ?? "Riprova.") }
        }.tint(GalleryStyle.accent).preferredColorScheme(.dark)
    }

    private func enhance() {
        guard ready, !isEnhancing else { return }
        isEnhancing = true
        let source = image
        Task {
            let result = await Task.detached(priority: .userInitiated) { PhotoEditorManager.shared.autoEnhance(image: source) }.value
            isEnhancing = false
            if let result { image = result; isEnhanced = true }
            else { errorMessage = "Non è stato possibile elaborare questa immagine." }
        }
    }
}

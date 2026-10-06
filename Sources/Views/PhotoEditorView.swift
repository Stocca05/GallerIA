import SwiftUI

struct PhotoAdjustments: Hashable {
    var brightness: Float = 0
    var contrast: Float = 1
    var saturation: Float = 1
}

struct PhotoEditorView: View {
    let originalImage: UIImage
    @State private var editedImage: UIImage
    @State private var adjustments = PhotoAdjustments()
    @State private var renderedAdjustments = PhotoAdjustments()
    @State private var isRendering = false
    @State private var isSaving = false
    @State private var showOriginal = false
    @State private var saved = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    init(image: UIImage) {
        originalImage = image
        _editedImage = State(initialValue: image)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(uiImage: showOriginal ? originalImage : editedImage)
                        .resizable().scaledToFit().frame(maxHeight: 380)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    Picker("Confronta", selection: $showOriginal) {
                        Text("Modificata").tag(false)
                        Text("Prima delle regolazioni").tag(true)
                    }.pickerStyle(.segmented)
                    VStack(spacing: 24) {
                        sliderRow("Luminosità", value: $adjustments.brightness, range: -0.5...0.5)
                        sliderRow("Contrasto", value: $adjustments.contrast, range: 0.5...1.5)
                        sliderRow("Saturazione", value: $adjustments.saturation, range: 0...2)
                    }.galleryPanel().disabled(isSaving)
                    HStack {
                        Button("Ripristina regolazioni") { adjustments = PhotoAdjustments() }
                            .disabled(isSaving || adjustments == PhotoAdjustments())
                        Spacer()
                        if isRendering { ProgressView().accessibilityLabel("Aggiornamento anteprima") }
                    }.font(.caption)
                    Text("Verrà creata una nuova foto. Il file di partenza non viene modificato. La copia non conserva posizione e altri metadati dell’originale.")
                        .font(.footnote).foregroundStyle(GalleryStyle.secondary)
                    Text("Dimensioni della copia: \(Int(editedImage.size.width * editedImage.scale)) × \(Int(editedImage.size.height * editedImage.scale)) pixel")
                        .font(.caption).foregroundStyle(GalleryStyle.secondary)
                    Button { save() } label: {
                        if isSaving { ProgressView().tint(GalleryStyle.background) }
                        else { Label("Salva una copia in Foto", systemImage: "square.and.arrow.down") }
                    }.buttonStyle(PrimaryButton())
                        .disabled(isSaving || isRendering || adjustments != renderedAdjustments)
                }.padding(22).frame(maxWidth: 700).frame(maxWidth: .infinity)
            }.background(GalleryStyle.background)
                .navigationTitle("Regola la foto").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Chiudi") { dismiss() }.disabled(isSaving) } }
                .interactiveDismissDisabled(isSaving)
                .task(id: adjustments) { await render() }
                .alert("Copia salvata", isPresented: $saved) { Button("Fatto") { dismiss() } }
                    message: { Text("La nuova immagine è nella libreria Foto. L’originale è rimasto invariato.") }
                .alert("Operazione non completata", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                    Button("OK") { errorMessage = nil }
                } message: { Text(errorMessage ?? "Riprova.") }
        }.tint(GalleryStyle.accent).preferredColorScheme(.dark)
    }

    private func sliderRow(_ title: String, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.subheadline.bold())
                Spacer()
                Text(value.wrappedValue.formatted(.number.precision(.fractionLength(2)))).monospacedDigit().font(.caption)
            }
            Slider(value: value, in: range).accessibilityLabel(title)
        }
    }

    private func render() async {
        let snapshot = adjustments
        isRendering = true
        do { try await Task.sleep(for: .milliseconds(150)) } catch { return }
        let source = originalImage
        let result = await Task.detached(priority: .userInitiated) {
            PhotoEditorManager.shared.applyManualAdjustments(image: source, brightness: snapshot.brightness,
                contrast: snapshot.contrast, saturation: snapshot.saturation)
        }.value
        guard !Task.isCancelled else { return }
        isRendering = false
        if let result { editedImage = result; renderedAdjustments = snapshot }
        else { errorMessage = "Impossibile applicare le regolazioni a questa immagine." }
    }

    private func save() {
        guard !isSaving, !isRendering, adjustments == renderedAdjustments else { return }
        isSaving = true
        let snapshot = editedImage
        Task {
            defer { isSaving = false }
            do { try await PhotoExportManager.saveCopy(snapshot); saved = true }
            catch { errorMessage = error.localizedDescription }
        }
    }
}

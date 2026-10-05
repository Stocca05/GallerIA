import SwiftUI
import Photos

struct PhotoEditorView: View {
    let originalImage: UIImage
    @State private var editedImage: UIImage

    @State private var brightness: Float = 0.0
    @State private var contrast: Float = 1.0
    @State private var saturation: Float = 1.0

    @Environment(\.dismiss) private var dismiss

    init(image: UIImage) {
        self.originalImage = image
        _editedImage = State(initialValue: image)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(uiImage: editedImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding()
                    .shadow(radius: 10)

                VStack(spacing: 24) {
                    sliderRow(title: "Luminosità", value: $brightness, range: -1.0...1.0)
                    sliderRow(title: "Contrasto", value: $contrast, range: 0.0...2.0)
                    sliderRow(title: "Saturazione", value: $saturation, range: 0.0...2.0)
                }
                .padding()
                .glassmorphism(cornerRadius: 20, borderOpacity: 0.2)
                .padding(.horizontal)

                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .foregroundColor(.white)
            .navigationTitle("Editor PRO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        // In a real app we would save to PhotoLibrary here
                        SoundManager.shared.playSuccess()
                        dismiss()
                    }
                    .bold()
                    .tint(.cyan)
                }
            }
            .onChange(of: brightness) { _ in applyFilters() }
            .onChange(of: contrast) { _ in applyFilters() }
            .onChange(of: saturation) { _ in applyFilters() }
        }
    }

    private func sliderRow(title: String, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.bold())

            Slider(value: value, in: range)
                .tint(.cyan)
        }
    }

    private func applyFilters() {
        // Debounce or dispatch in background to avoid UI hangs
        Task.detached(priority: .userInitiated) {
            let result = PhotoEditorManager.shared.applyManualAdjustments(
                image: self.originalImage,
                brightness: self.brightness,
                contrast: self.contrast,
                saturation: self.saturation
            )
            await MainActor.run {
                if let result = result {
                    self.editedImage = result
                }
            }
        }
    }
}

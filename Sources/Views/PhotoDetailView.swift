import SwiftUI

struct PhotoDetailView: View {
    @State var image: UIImage
    let score: Float
    @Environment(\.dismiss) private var dismiss

    @State private var isEnhancing = false
    @State private var isEnhanced = false
    @State private var showManualEditor = false
    @State private var showOCR = false
    @State private var isWatermarked = true

    var body: some View {
        NavigationStack {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding()
                    .shadow(radius: 10)
                    .overlay(alignment: .topTrailing) {
                        if isEnhanced {
                            Text(String(localized: "photo.enhanced"))
                                .font(.caption.bold())
                                .padding(6)
                                .background(Color.yellow, in: Capsule())
                                .foregroundColor(.black)
                                .padding(24)
                        }
                    }

                VStack(spacing: 12) {
                    Text(String(localized: "photo.neural_analysis"))
                        .font(.title2.bold())

                    HStack {
                        Text(String(localized: "photo.aesthetic_affinity"))
                        Spacer()
                        Text("\(Int(score * 100))%")
                            .bold()
                            .foregroundColor(score >= 0.8 ? .green : .orange)
                    }

                    ProgressView(value: score, total: 1.0)
                        .tint(score >= 0.8 ? .green : .orange)
                }
                .padding()
                .glassmorphism(cornerRadius: 16, borderOpacity: 0.2)
                .padding(.horizontal)

                if !isEnhanced {
                    HStack(spacing: 12) {
                        Button {
                            enhanceImage()
                        } label: {
                            if isEnhancing {
                                ProgressView().tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text(String(localized: "photo.enhance_magic"))
                                }
                                .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 16))

                        Button {
                            showOCR = true
                        } label: {
                            Image(systemName: "text.viewfinder")
                                .font(.headline)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                        Button {
                            showManualEditor = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.headline)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                Spacer()
            }
            .navigationTitle("Dettaglio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    let shareImage = isWatermarked ? WatermarkManager.shared.applyWatermark(to: image) : image

                    ShareLink(
                        item: Image(uiImage: shareImage),
                        preview: SharePreview("Scelto dall'IA di GallerIA", image: Image(uiImage: shareImage))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.close")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Toggle("Applica Filigrana", isOn: $isWatermarked)
                        .padding(.horizontal)
                }
            }
            .sheet(isPresented: $showManualEditor) {
                PhotoEditorView(image: image)
            }
            .sheet(isPresented: $showOCR) {
                OCRView(image: image)
            }
        }
    }

    private func enhanceImage() {
        guard !isEnhancing else { return }
        isEnhancing = true

        let currentImage = self.image

        Task.detached(priority: .userInitiated) {
            let enhanced = PhotoEditorManager.shared.autoEnhance(image: currentImage)
            await MainActor.run {
                if let enhanced = enhanced {
                    self.image = enhanced
                    self.isEnhanced = true
                    HapticSymphonyManager.shared.playSuccessRipple()
                    SoundManager.shared.playSuccess()
                }
                self.isEnhancing = false
            }
        }
    }
}

import SwiftUI

struct OCRView: View {
    let image: UIImage
    @State private var extractedText: String = ""
    @State private var isExtracting = true

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.black, Color(red: 0.1, green: 0.1, blue: 0.3)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 10)
                        .padding()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "text.viewfinder")
                                .foregroundColor(.cyan)
                            Text("Testo Rilevato")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                            Spacer()
                            if !isExtracting && !extractedText.isEmpty {
                                Button("Copia") {
                                    UIPasteboard.general.string = extractedText
                                    HapticSymphonyManager.shared.playSuccessRipple()
                                }
                                .font(.caption.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.cyan, in: Capsule())
                            }
                        }

                        ScrollView {
                            if isExtracting {
                                ProgressView()
                                    .tint(.cyan)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 40)
                            } else if extractedText.isEmpty {
                                Text("Nessun testo rilevato in questa immagine.")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 40)
                            } else {
                                Text(extractedText)
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .glassmorphism(cornerRadius: 24, borderOpacity: 0.2)
                    .padding()
                }
            }
            .navigationTitle("Scanner OCR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
        .task {
            if let cgImage = image.cgImage {
                let text = await OCRManager.shared.extractText(from: cgImage)
                await MainActor.run {
                    self.extractedText = text
                    self.isExtracting = false
                    if !text.isEmpty {
                        SoundManager.shared.playSuccess()
                    }
                }
            } else {
                isExtracting = false
            }
        }
    }
}

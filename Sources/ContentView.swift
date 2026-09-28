import SwiftUI
import UIKit
import Combine

struct ContentView: View {
    @StateObject var viewModel = GallerIAViewModel()
    @State private var showGallery = false
    @State private var accessDenied = false
    @State private var showResetAlert = false
    @State private var isWaitingForInitialBatch = false

    var body: some View {
        if viewModel.isFinished {
            ZStack {
                LinearGradient(colors: [.purple, .black, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Abbiamo imparato la tua estetica! 🎉")
                        .font(.title)
                        .multilineTextAlignment(.center)
                    Text("Il modello neurale ora conosce i tuoi gusti.")
                        .multilineTextAlignment(.center)

                    Button(action: { showGallery = true }) {
                        Text("Vedi la Galleria")
                            .bold()
                            .padding(.horizontal, 36)
                            .padding(.vertical, 20)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }

                    Button {
                        viewModel.photoManager.loadNextBatch()
                        if !viewModel.photoManager.assets.isEmpty {
                            viewModel.isFinished = false
                            viewModel.loadNextPhoto()
                        }
                    } label: {
                        Text("Continua ad addestrare")
                            .bold()
                            .padding(.horizontal, 36)
                            .padding(.vertical, 20)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }

                    Button("Reset Modello Neurale") {
                        showResetAlert = true
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 24)
                }
                .foregroundColor(.white)
                .padding()
            }
            .fullScreenCover(isPresented: $showGallery) {
                GalleryView(classifier: viewModel.classifier, mlManager: viewModel.mlManager)
            }
            .alert("Sei sicuro?", isPresented: $showResetAlert) {
                Button("Annulla", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    isWaitingForInitialBatch = true
                    viewModel.resetBrain()
                }
            } message: {
                Text("Perderai tutto l'apprendimento neurale sui tuoi gusti estetici.")
            }
        } else if let currentImage = viewModel.currentImage {
            ZStack {
                Image(uiImage: currentImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 50)
                    .opacity(0.6)

                VStack {
                    Text("Score: \(Int(viewModel.currentScore * 100))%")
                        .font(.title.bold())
                        .foregroundColor(viewModel.currentScore >= 0.5 ? .green : .red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.45))
                        .cornerRadius(16)

                    CardView(image: currentImage, score: viewModel.currentScore) { liked in
                        let haptic = UIImpactFeedbackGenerator(style: .medium)
                        haptic.impactOccurred()
                        viewModel.rate(liked: liked)
                    }
                    .id(currentImage)
                }
                .padding()
            }
            .animation(.easeInOut, value: viewModel.currentImage)
        } else {
            ZStack {
                LinearGradient(colors: [.purple, .black, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 36) {
                    Text("GallerIA")
                        .font(.system(size: 50, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .purple, radius: 20)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "hand.draw.fill")
                            Text("Fai swipe a destra per le foto che ami, a sinistra per quelle che odi.")
                        }

                        HStack {
                            Image(systemName: "brain.head.profile")
                            Text("Il modello neurale imparerà i tuoi gusti.")
                        }

                        HStack {
                            Image(systemName: "sparkles")
                            Text("Scopri la tua galleria fotografica perfetta.")
                        }
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .font(.callout)

                    if accessDenied {
                        Text("Accesso alle foto negato. Vai in Impostazioni.")
                            .foregroundColor(.red)
                            .bold()
                            .multilineTextAlignment(.center)
                    } else {
                        Button {
                            isWaitingForInitialBatch = true
                            viewModel.photoManager.requestAccessAndFetch()
                        } label: {
                            Text("Inizia Scansione")
                                .foregroundColor(.white)
                                .bold()
                                .padding(.horizontal, 36)
                                .padding(.vertical, 20)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding()
            }
            .onReceive(
                viewModel.photoManager.$accessDenied
                    .receive(on: DispatchQueue.main)
            ) { accessDenied in
                self.accessDenied = accessDenied
            }
            .onReceive(
                viewModel.photoManager.$assets
                    .first(where: { !$0.isEmpty })
                    .receive(on: DispatchQueue.main)
            ) { _ in
                guard isWaitingForInitialBatch else { return }
                isWaitingForInitialBatch = false
                viewModel.loadNextPhoto()
            }
        }
    }
}

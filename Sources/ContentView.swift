import SwiftUI
import UIKit
import Combine

struct ContentView: View {
    @StateObject var viewModel = GallerIAViewModel()
    @State private var showGallery = false
    @State private var showStats = false
    @State private var showSettings = false
    @State private var accessDenied = false
    @State private var showResetAlert = false
    @State private var isWaitingForInitialBatch = false

    var body: some View {
        mainContent
            .safeAreaInset(edge: .top) {
                HStack {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Impostazioni")
                    Button {
                        showStats = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Statistiche neurali")
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .sheet(isPresented: $showStats) {
                StatsView(classifier: viewModel.classifier)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(classifier: viewModel.classifier)
            }
    }

    @ViewBuilder
    private var mainContent: some View {
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
            MainSwipingView(currentImage: currentImage, currentScore: viewModel.currentScore) { liked in
                viewModel.rate(liked: liked)
            }
            .animation(.easeInOut, value: viewModel.currentImage)
        } else {
            OnboardingView(accessDenied: accessDenied) {
                isWaitingForInitialBatch = true
                viewModel.photoManager.requestAccessAndFetch()
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

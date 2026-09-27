import SwiftUI
import UIKit
import Combine

struct ContentView: View {
    @StateObject var viewModel = GallerIAViewModel()

    var body: some View {
        if viewModel.isFinished {
            VStack {
                Text("Abbiamo imparato la tua estetica! 🎉")
                    .font(.title)
                    .multilineTextAlignment(.center)
                Text("Il modello neurale ora conosce i tuoi gusti.")
                    .foregroundColor(.secondary)
            }
            .padding()
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
                        .font(.largeTitle)
                        .foregroundColor(viewModel.currentScore >= 0.5 ? .green : .red)

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
            VStack {
                Text("GallerIA")

                Button("Inizia Scansione") {
                    viewModel.photoManager.requestAccessAndFetch()
                }
            }
            .onReceive(
                viewModel.photoManager.$assets
                    .first(where: { !$0.isEmpty })
                    .receive(on: DispatchQueue.main)
            ) { _ in
                viewModel.loadNextPhoto()
            }
        }
    }
}

import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var viewModel = GallerIAViewModel()
    @StateObject private var cleanupManager = CleanupManager(mlManager: MLManager())
    @State private var selectedTab = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(viewModel: DashboardViewModel(classifier: viewModel.classifier, mlManager: viewModel.mlManager), cleanupManager: cleanupManager, photoManager: viewModel.photoManager, onTrain: { selectedTab = 1 })
            }.tabItem { Label("La tua libreria", systemImage: "square.grid.2x2") }.tag(0)
            NavigationStack {
                TrainingTabView(viewModel: viewModel)
                    .navigationTitle("Il tuo gusto")
                    .navigationBarTitleDisplayMode(.inline)
            }.tabItem { Label("Seleziona", systemImage: "heart") }.tag(1)
            SettingsView(classifier: viewModel.classifier)
                .tabItem { Label("Impostazioni", systemImage: "slider.horizontal.3") }.tag(2)
        }
        .tint(GalleryStyle.accent)
        .preferredColorScheme(.dark)
        .task { viewModel.photoManager.refreshIfAuthorized() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.photoManager.refreshIfAuthorized() }
            if phase == .background && !viewModel.classifier.batchEmbeddings.isEmpty { viewModel.performTraining() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("GallerIALibraryChanged"))) { _ in
            viewModel.photoManager.requestAccessAndFetch()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("GallerIAReset"))) { _ in
            viewModel.resetBrain()
        }
        .onReceive(viewModel.photoManager.$libraryRevision) { revision in
            if revision > 0 { viewModel.reloadSession() }
        }
    }
}

struct TrainingTabView: View {
    @ObservedObject var viewModel: GallerIAViewModel

    var body: some View {
        ZStack {
            GalleryStyle.background.ignoresSafeArea()
            if viewModel.isTraining {
                ProgressView("La selezione si aggiorna…").tint(GalleryStyle.accent)
            } else if !viewModel.cardQueue.isEmpty && viewModel.photoManager.isAuthorized {
                let displayedID = viewModel.cardQueue.first?.id
                MainSwipingView(deck: viewModel.cardQueue, photosRated: viewModel.photosRated,
                    totalPhotos: viewModel.photoManager.totalPhotos, trashCount: 0,
                    pendingTrainings: viewModel.pendingTrainings,
                    rateAction: { viewModel.rate(liked: $0, expectedID: displayedID) }, undoAction: { viewModel.undoLast() },
                    trainAction: { viewModel.performTraining() }, skipAction: { viewModel.skipCurrentPhoto() })
            } else {
                ContentUnavailableView {
                    Label(viewModel.photoManager.isAuthorized ? "Tutto in ordine" : "Partiamo dalle tue foto", systemImage: "photo.stack")
                } description: {
                    Text(viewModel.photoManager.isAuthorized ? "Hai visto tutte le foto disponibili. Aggiungi altri ricordi alla libreria per continuare." : "Consenti l’accesso dalla schermata La tua libreria per creare la tua selezione.")
                }
            }
        }
    }
}

import SwiftUI
import SwiftData

@main
struct GallerIAApp: App {
    @StateObject private var proManager = ProManager.shared
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("isPrivacyLockEnabled") private var privacyEnabled = false
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--reset-onboarding") {
            UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--preview-editor") {
                    PhotoEditorView(image: EditorPreviewFixture.image)
                } else {
                    appContent
                }
                #else
                appContent
                #endif
            }.background(PrivacyShield(enabled: privacyEnabled, phase: scenePhase, authManager: authManager))
        }
        .modelContainer(for: [EmbeddingModel.self, RatedPhoto.self])
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { authManager.lock() }
            if phase == .active { Task { await proManager.refreshEntitlements() } }
        }
    }

    private var appContent: some View {
        ZStack {
            if !hasSeenOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .environmentObject(proManager)
                    .environmentObject(authManager)
            }
        }
    }
}

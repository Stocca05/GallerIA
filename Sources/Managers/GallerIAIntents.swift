import AppIntents
import SwiftUI

struct CleanupIntent: AppIntent {
    static var title: LocalizedStringResource = "Apri GallerIA"
    static var description = IntentDescription("Apri la tua libreria in GallerIA per rivedere foto e suggerimenti.")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct GallerIAShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CleanupIntent(),
            phrases: [
                "Apri la libreria con \(.applicationName)"
            ],
            shortTitle: "Apri GallerIA",
            systemImageName: "sparkles"
        )
    }
}

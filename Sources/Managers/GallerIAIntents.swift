import AppIntents
import SwiftUI

struct CleanupIntent: AppIntent {
    static var title: LocalizedStringResource = "Pulisci Galleria"
    static var description = IntentDescription("Avvia la pulizia intelligente delle foto usando l'IA di GallerIA.")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        // Since we are opening the app, we can just trigger a notification
        // or a deep link that the app intercepts.
        NotificationCenter.default.post(name: NSNotification.Name("TriggerCleanupIntent"), object: nil)
        return .result()
    }
}

struct GallerIAShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CleanupIntent(),
            phrases: [
                "Pulisci la galleria con \(.applicationName)",
                "Trova foto brutte con \(.applicationName)"
            ],
            shortTitle: "Pulisci Galleria",
            systemImageName: "sparkles"
        )
    }
}

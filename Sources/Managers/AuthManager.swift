import LocalAuthentication
import SwiftUI

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var isAuthenticated = false
    @Published private(set) var isAuthenticating = false
    @Published private(set) var errorMessage: String?
    @AppStorage("isPrivacyLockEnabled") var isPrivacyLockEnabled = false
    private var context: LAContext?
    private var generation = UUID()
    private init() {}

    func canEnableLock() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    func authenticate() {
        guard !isAuthenticating else { return }
        guard isPrivacyLockEnabled else { isAuthenticated = true; return }
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            errorMessage = "Lo sblocco del dispositivo non è disponibile. Configura un codice nelle Impostazioni di iOS."
            return
        }
        self.context = context
        let token = UUID()
        generation = token
        isAuthenticating = true
        errorMessage = nil
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Sblocca GallerIA per accedere ai tuoi ricordi.") { success, error in
            Task { @MainActor in
                guard self.generation == token else { return }
                self.isAuthenticating = false
                self.isAuthenticated = success
                if !success { self.errorMessage = "Sblocco non completato. Puoi riprovare con il codice del dispositivo." }
            }
        }
    }

    func lock() {
        guard isPrivacyLockEnabled else { return }
        generation = UUID()
        context?.invalidate()
        context = nil
        errorMessage = nil
        isAuthenticating = false
        isAuthenticated = false
    }
}

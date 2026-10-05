import LocalAuthentication
import SwiftUI

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @AppStorage("isPrivacyLockEnabled") var isPrivacyLockEnabled = false

    private init() {}

    func authenticate() {
        guard isPrivacyLockEnabled else {
            isAuthenticated = true
            return
        }

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Sblocca GallerIA per accedere ai tuoi capolavori."

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isAuthenticated = true
                    } else {
                        // Error handling could go here
                        self.isAuthenticated = false
                    }
                }
            }
        } else {
            // No biometrics available, fallback to true or allow pin
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
        }
    }

    func lock() {
        if isPrivacyLockEnabled {
            isAuthenticated = false
        }
    }
}

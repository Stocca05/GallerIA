import SwiftUI

struct LockView: View {
    @EnvironmentObject var authManager: AuthManager
    var body: some View {
        ZStack {
            GalleryStyle.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "lock.shield").font(.system(size: 64)).foregroundStyle(GalleryStyle.accent)
                Text("I tuoi ricordi sono al sicuro").font(.title2.bold()).multilineTextAlignment(.center)
                Text("Sblocca GallerIA con Face ID, Touch ID o il codice del dispositivo.")
                    .font(.subheadline).foregroundStyle(GalleryStyle.secondary).multilineTextAlignment(.center)
                if let error = authManager.errorMessage { Text(error).font(.footnote).multilineTextAlignment(.center) }
                Button("Sblocca GallerIA") { authManager.authenticate() }
                    .buttonStyle(PrimaryButton()).disabled(authManager.isAuthenticating)
            }.padding(28).frame(maxWidth: 500)
        }.preferredColorScheme(.dark)
            .onAppear { if authManager.errorMessage == nil { authManager.authenticate() } }
    }
}

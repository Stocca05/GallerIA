import SwiftUI

struct LockView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .purple.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Image(systemName: "faceid")
                    .font(.system(size: 80))
                    .foregroundColor(.cyan)
                    .breathing()

                Text("GallerIA è bloccata")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Button("Sblocca con Face ID") {
                    authManager.authenticate()
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding()
                .background(Color.cyan, in: Capsule())
            }
        }
        .onAppear {
            authManager.authenticate()
        }
    }
}

import SwiftUI

struct OnboardingView: View {
    let accessDenied: Bool
    let startAction: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple, .black, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 36) {
                Text("GallerIA")
                    .font(.system(size: 50, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .purple, radius: 20)

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "hand.draw.fill")
                        Text("Fai swipe a destra per le foto che ami, a sinistra per quelle che odi.")
                    }
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("Il modello neurale imparerà i tuoi gusti.")
                    }
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Scopri la tua galleria fotografica perfetta.")
                    }
                }
                .foregroundColor(.white.opacity(0.9))
                .font(.callout)

                if accessDenied {
                    Text("Accesso alle foto negato. Vai in Impostazioni.")
                        .foregroundColor(.red)
                        .bold()
                        .multilineTextAlignment(.center)
                } else {
                    Button(action: startAction) {
                        Text("Inizia Scansione")
                            .foregroundColor(.white)
                            .bold()
                            .padding(.horizontal, 36)
                            .padding(.vertical, 20)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
        }
    }
}

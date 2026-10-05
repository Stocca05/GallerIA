import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false

    var body: some View {
        ZStack {
            GalleryStyle.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Label("GallerIA", systemImage: "square.stack.3d.up")
                        .font(.title3.weight(.semibold))
                    ZStack {
                        RoundedRectangle(cornerRadius: 32).fill(GalleryStyle.accent.opacity(0.10))
                            .rotationEffect(.degrees(-8)).padding(12)
                        VStack(spacing: 18) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 72, weight: .ultraLight))
                            Text("MENO RUMORE. PIÙ RICORDI.")
                                .font(.caption.weight(.semibold)).tracking(2)
                        }.foregroundStyle(GalleryStyle.accent)
                    }.frame(height: 230).padding(.vertical, 8)
                    Text("La tua libreria.\nIl tuo punto di vista.")
                        .font(.system(size: 40, weight: .semibold, design: .serif))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Riscopri le foto che ami e fai spazio a quello che verrà.")
                        .font(.title3).foregroundStyle(GalleryStyle.secondary)
                    VStack(alignment: .leading, spacing: 18) {
                        Label("Una selezione che impara dai tuoi gusti", systemImage: "sparkles")
                        Label("Foto simili e screenshot da rivedere", systemImage: "square.on.square")
                        Label("Analisi delle immagini sul dispositivo", systemImage: "lock.shield")
                    }.font(.subheadline).galleryPanel()
                    Button("Crea la tua selezione") { hasSeenOnboarding = true }
                        .buttonStyle(PrimaryButton())
                    Text("Decidi tu quali foto condividere con l’app. Nessuna foto viene eliminata mentre esprimi le tue preferenze.")
                        .font(.footnote).foregroundStyle(GalleryStyle.secondary)
                }.padding(28).frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
            }
        }.preferredColorScheme(.dark)
    }
}

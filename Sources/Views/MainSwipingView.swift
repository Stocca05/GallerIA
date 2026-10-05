import SwiftUI

struct MainSwipingView: View {
    let deck: [PhotoCard]
    let photosRated: Int
    let totalPhotos: Int
    let trashCount: Int
    let pendingTrainings: Int
    let rateAction: (Bool) -> Void
    let undoAction: () -> Void
    let trainAction: () -> Void
    let skipAction: () -> Void
    private var ready: Bool { deck.first?.embedding != nil }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("Quali foto ti rappresentano?").font(.headline)
                    Spacer()
                    Text("\(photosRated) scelte").font(.caption).foregroundStyle(GalleryStyle.secondary)
                }
                if let card = deck.first, let image = card.image {
                    CardView(image: image, score: card.score, onSwipe: rateAction)
                        .id(card.id).allowsHitTesting(ready)
                        .accessibilityAction(named: "Mi piace") { if ready { rateAction(true) } }
                        .accessibilityAction(named: "Non fa per me") { if ready { rateAction(false) } }
                } else {
                    ProgressView("Caricamento della foto…").frame(height: 420)
                }
                HStack(spacing: 12) {
                    Button { rateAction(false) } label: {
                        Label("Non fa per me", systemImage: "minus").frame(maxWidth: .infinity).padding(.vertical, 18)
                    }.background(GalleryStyle.surface, in: RoundedRectangle(cornerRadius: 18))
                    Button { rateAction(true) } label: {
                        Label("Mi piace", systemImage: "heart.fill").frame(maxWidth: .infinity).padding(.vertical, 18)
                    }.foregroundStyle(GalleryStyle.background)
                        .background(GalleryStyle.accent, in: RoundedRectangle(cornerRadius: 18))
                }.font(.subheadline.bold()).disabled(!ready).opacity(ready ? 1 : 0.4)
                Text("Stai insegnando il tuo gusto. Nessuna foto viene eliminata.")
                    .font(.caption).foregroundStyle(GalleryStyle.secondary).multilineTextAlignment(.center)
                HStack {
                    Button(action: undoAction) { Label("Annulla", systemImage: "arrow.uturn.backward") }
                    Spacer()
                    Button("Salva preferenze (\(pendingTrainings))", action: trainAction)
                }.font(.caption).disabled(pendingTrainings == 0)
                Button("Salta questa foto", action: skipAction).font(.caption).foregroundStyle(GalleryStyle.secondary)
                if !ready { Text("Preparazione della foto. Le immagini su iCloud richiedono una connessione.").font(.caption).foregroundStyle(GalleryStyle.secondary) }
            }.padding(22).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
    }
}

import SwiftUI

struct ProView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var proManager: ProManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Label("GALLERIA PRO", systemImage: "sparkles").font(.caption.bold()).tracking(2)
                        .foregroundStyle(GalleryStyle.accent)
                    Text("Più spazio.\nMeno disordine.")
                        .font(.system(size: 42, weight: .medium, design: .serif))
                    Text("Gli strumenti per prenderti cura della tua libreria, in un unico acquisto.")
                        .foregroundStyle(GalleryStyle.secondary)
                    VStack(alignment: .leading, spacing: 24) {
                        feature("square.on.square", "Confronta le foto simili", "Rivedi i gruppi suggeriti e scegli cosa tenere.")
                        feature("viewfinder", "Metti ordine negli screenshot", "Seleziona quelli che non ti servono più.")
                        feature("video", "Rivedi i video recenti", "Un posto solo per scegliere quali eliminare.")
                    }.galleryPanel()
                    Text("L’analisi considera fino a 500 foto recenti, 100 screenshot e 100 video. Ogni eliminazione richiede la tua conferma.")
                        .font(.footnote).foregroundStyle(GalleryStyle.secondary)
                    if let message = proManager.message {
                        Text(message).font(.subheadline).foregroundStyle(GalleryStyle.secondary)
                    }
                    Button {
                        proManager.purchasePro()
                    } label: {
                        if proManager.isLoading { ProgressView().tint(GalleryStyle.background) }
                        else { Text(proManager.isPro ? "Pro è attivo" : proManager.product.map { "Sblocca Pro · \($0.displayPrice)" } ?? "Acquisto non disponibile") }
                    }.buttonStyle(PrimaryButton())
                        .disabled(proManager.product == nil || proManager.isLoading || proManager.isPro)
                        .opacity(proManager.product == nil ? 0.5 : 1)
                    HStack {
                        Button("Ripristina acquisti") { proManager.restorePurchases() }
                        Spacer()
                        if proManager.product == nil { Button("Riprova") { Task { await proManager.loadProduct() } } }
                    }.font(.footnote).disabled(proManager.isLoading)
                    Text("Pagamento tramite il tuo account Apple. Acquisto singolo, senza rinnovo automatico.")
                        .font(.caption).foregroundStyle(GalleryStyle.secondary)
                }.padding(26).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }.background(GalleryStyle.background)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Chiudi") { dismiss() } } }
        }.tint(GalleryStyle.accent).preferredColorScheme(.dark)
    }

    private func feature(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon).font(.title2).foregroundStyle(GalleryStyle.accent).frame(width: 28)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(GalleryStyle.secondary)
            }
        }
    }
}

import SwiftUI

struct ProView: View {
    @State private var showingPurchaseInfo = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.yellow)
                        .accessibilityHidden(true)

                    Text("Sblocca GallerIA PRO")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    VStack(alignment: .leading, spacing: 24) {
                        benefit("Nessun limite di batch")
                        benefit("Filtri avanzati")
                        benefit("Sync iCloud")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

                    Button {
                        showingPurchaseInfo = true
                    } label: {
                        Text("Acquista a 4.99$")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .foregroundStyle(.black)
                            .background(.yellow, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 500)
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(.white)
        .navigationTitle("GallerIA PRO")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Acquisto non ancora disponibile", isPresented: $showingPurchaseInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("GallerIA PRO sarà disponibile prossimamente. Nessun addebito è stato effettuato.")
        }
    }

    private func benefit(_ title: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
        }
    }
}

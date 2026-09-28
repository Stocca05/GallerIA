import SwiftUI

struct StatsView: View {
    let classifier: AestheticClassifier
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.purple, .black, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 64))
                            .foregroundStyle(.cyan)
                            .padding(24)
                            .background(.ultraThinMaterial, in: Circle())
                            .accessibilityHidden(true)

                        Text("La tua estetica, in numeri")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)

                        Text("Il percorso di apprendimento del tuo modello neurale.")
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)

                        statisticCard(
                            title: "Iterazioni di addestramento: \(classifier.iterations)",
                            detail: "Batch di apprendimento completati con le tue valutazioni.",
                            icon: "chart.bar.fill",
                            color: .cyan
                        )

                        statisticCard(
                            title: "Parametri del tensore: \(classifier.weights?.count ?? 0)",
                            detail: "Pesi del modello che rappresentano i tuoi gusti estetici.",
                            icon: "square.stack.3d.up.fill",
                            color: .purple
                        )
                    }
                    .padding(24)
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                }
            }
            .foregroundStyle(.white)
            .navigationTitle("Statistiche neurali")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                    .tint(.white)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func statisticCard(title: String, detail: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .monospacedDigit()

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

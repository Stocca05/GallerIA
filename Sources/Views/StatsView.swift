import SwiftUI
import Charts

struct StatsView: View {
    let classifier: AestheticClassifier
    @Environment(\.dismiss) private var dismiss

    struct TrendData: Identifiable {
        let id = UUID()
        let day: String
        let accuracy: Double
    }

    let mockData: [TrendData] = [
        TrendData(day: "Lun", accuracy: 0.3),
        TrendData(day: "Mar", accuracy: 0.5),
        TrendData(day: "Mer", accuracy: 0.65),
        TrendData(day: "Gio", accuracy: 0.8),
        TrendData(day: "Ven", accuracy: 0.85),
        TrendData(day: "Sab", accuracy: 0.92),
        TrendData(day: "Dom", accuracy: 0.98)
    ]

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

                        // The Swift Chart
                        VStack(alignment: .leading) {
                            Text("Accuratezza Rete Neurale")
                                .font(.headline)

                            Chart(mockData) { item in
                                LineMark(
                                    x: .value("Giorno", item.day),
                                    y: .value("Precisione", item.accuracy)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.cyan)

                                AreaMark(
                                    x: .value("Giorno", item.day),
                                    y: .value("Precisione", item.accuracy)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cyan.opacity(0.5), .cyan.opacity(0.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                            .frame(height: 200)
                            .chartYScale(domain: 0...1.0)
                        }
                        .padding()
                        .glassmorphism(cornerRadius: 24, borderOpacity: 0.15)

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

                        statisticCard(
                            title: "Foto valutate: \(classifier.totalSamples)",
                            detail: "Campioni di addestramento usati per costruire il tuo profilo estetico.",
                            icon: "photo.stack.fill",
                            color: .orange
                        )

                        if let pdfURL = PDFReportGenerator.shared.generateAestheticReport(iterations: classifier.iterations, totalSamples: classifier.totalSamples, score: 0.88) {
                            ShareLink(item: pdfURL) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                    Text("Esporta Report Neurale (PDF)")
                                }
                                .font(.headline.bold())
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cyan, in: Capsule())
                            }
                            .padding(.top, 16)
                        }
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
        .glassmorphism(cornerRadius: 24, borderOpacity: 0.15)
        .accessibilityElement(children: .combine)
    }
}

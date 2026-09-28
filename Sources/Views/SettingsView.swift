import SwiftUI

struct SettingsView: View {
    let classifier: AestheticClassifier
    @AppStorage("aestheticThreshold") var threshold: Double = 0.5
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Motore Neurale") {
                    HStack {
                        Text("Soglia estetica")
                        Spacer()
                        Text(threshold, format: .percent.precision(.fractionLength(0)))
                            .monospacedDigit()
                    }
                    Slider(value: $threshold, in: 0.1...0.9, step: 0.1)
                        .accessibilityLabel("Soglia estetica")
                }

                Section("Premium") {
                    NavigationLink {
                        ProView()
                    } label: {
                        Label("GallerIA PRO", systemImage: "crown.fill")
                    }
                }

                Section("Azioni di Pericolo") {
                    Button("Formatta Cervello", role: .destructive) {
                        classifier.reset()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

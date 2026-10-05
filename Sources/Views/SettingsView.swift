import SwiftUI

struct SettingsView: View {
    let classifier: AestheticClassifier
    @AppStorage("aestheticThreshold") private var threshold = 0.5
    @AppStorage("isPrivacyLockEnabled") private var privacyLock = false
    @State private var confirmReset = false
    @State private var showPrivacy = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink { ProView() } label: {
                        Label("Scopri GallerIA Pro", systemImage: "sparkles")
                    }
                } footer: { Text("Un unico acquisto per gli strumenti di pulizia.") }
                Section("La tua selezione") {
                    HStack {
                        Text("Affinità minima")
                        Spacer()
                        Text(threshold, format: .percent.precision(.fractionLength(0))).monospacedDigit()
                    }
                    Slider(value: $threshold, in: 0.1...0.9, step: 0.1)
                        .accessibilityLabel("Affinità minima per i suggerimenti")
                    Text("Una soglia più alta rende la raccolta più selettiva. Il punteggio riflette le tue preferenze, non la qualità assoluta di una foto.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Privacy") {
                    Toggle("Richiedi sblocco del dispositivo", isOn: $privacyLock)
                    Button("Come vengono usati i tuoi dati") { showPrivacy = true }
                    Button("Gestisci accesso alle foto") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                }
                Section {
                    Button("Azzera le preferenze apprese", role: .destructive) { confirmReset = true }
                } footer: { Text("Le tue foto restano nella libreria. La selezione ricomincia a imparare dai prossimi voti.") }
                Section {
                    LabeledContent("Versione", value: "1.0")
                    Text("Fatto per i tuoi ricordi.").foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden).background(GalleryStyle.background)
            .navigationTitle("Impostazioni")
            .confirmationDialog("Azzerare le preferenze?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Azzera preferenze", role: .destructive) {
                    classifier.reset()
                    HistoryManager.shared.reset()
                    NotificationCenter.default.post(name: .init("GallerIAReset"), object: nil)
                }
            }
            .sheet(isPresented: $showPrivacy) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("I tuoi ricordi, sotto il tuo controllo.").font(.largeTitle.weight(.medium))
                            Text("GallerIA usa Apple Vision sul dispositivo per analizzare le foto a cui concedi accesso. Non invia le immagini a servizi di intelligenza artificiale esterni.")
                            Text("Preferenze ed estratti numerici delle immagini sono conservati nell’area locale dell’app. Le immagini presenti solo su iCloud possono essere scaricate tramite la libreria Foto per completare l’analisi.")
                            Text("Gli acquisti sono gestiti da Apple. Puoi modificare i permessi Foto dalle Impostazioni di iOS e azzerare le preferenze apprese da questa schermata.")
                            Text("I suggerimenti possono essere imprecisi. Sei sempre tu a scegliere cosa eliminare.")
                        }.padding(24)
                    }.navigationTitle("Privacy").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Chiudi") { showPrivacy = false } } }
                }
            }
        }
    }
}

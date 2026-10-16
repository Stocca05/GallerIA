import SwiftUI

struct SettingsView: View {
    let classifier: AestheticClassifier
    @AppStorage("aestheticThreshold") private var threshold = 0.5
    @AppStorage("isPrivacyLockEnabled") private var privacyLock = false
    @ObservedObject private var decisions = PhotoDecisionStore.shared
    @State private var confirmErase = false
    @State private var storageError: String?
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
                Section("I tuoi ricordi") {
                    NavigationLink { ProtectedPhotosView() } label: {
                        Label("Ricordi protetti (\(decisions.data.protectedIDs.count))", systemImage: "lock.shield")
                    }
                    NavigationLink { HelpView() } label: { Label("Guida e assistenza", systemImage: "questionmark.circle") }
                }
                Section("Privacy") {
                    Toggle("Richiedi sblocco del dispositivo", isOn: Binding(get: { privacyLock }, set: { enabled in
                        if !enabled || AuthManager.shared.canEnableLock() { privacyLock = enabled }
                        else { storageError = "Prima configura un codice di sblocco nelle Impostazioni di iOS." }
                    }))
                    Button("Come vengono usati i tuoi dati") { showPrivacy = true }
                    if let url = ReleaseConfiguration.privacyURL { Link("Informativa privacy completa", destination: url) }
                    Button("Gestisci accesso alle foto") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                }
                Section {
                    Button("Azzera le preferenze apprese", role: .destructive) { confirmReset = true }
                    Button("Elimina tutti i dati locali", role: .destructive) { confirmErase = true }
                } footer: { Text("Azzerare le preferenze conserva i ricordi protetti. Eliminare tutti i dati locali rimuove anche le protezioni e la cache; le foto e l’acquisto Pro restano intatti.") }
                Section {
                    LabeledContent("Versione", value: ReleaseConfiguration.version)
                    Text("Fatto per i tuoi ricordi.").foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden).background(GalleryStyle.background)
            .navigationTitle("Impostazioni")
            .confirmationDialog("Azzerare le preferenze?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Azzera preferenze", role: .destructive) {
                    NotificationCenter.default.post(name: .init("GallerIAReset"), object: nil)
                }
            }
            .alert("Eliminare preferenze, protezioni e cache locali?", isPresented: $confirmErase) {
                Button("Elimina dati locali", role: .destructive) {
                    do {
                        try decisions.reset()
                        try EmbeddingCache.shared.clear()
                        NotificationCenter.default.post(name: .init("GallerIAReset"), object: nil)
                    } catch { storageError = error.localizedDescription }
                }
                Button("Annulla", role: .cancel) { }
            } message: { Text("Nessuna foto verrà cancellata. I ricordi non saranno più protetti nell’app.") }
            .alert("Operazione non completata", isPresented: Binding(get: { storageError != nil }, set: { if !$0 { storageError = nil } })) {
                Button("OK") { storageError = nil }
            } message: { Text(storageError ?? "Riprova.") }
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

import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Section("Comincia in un minuto") {
                Text("1. Concedi accesso alle foto che vuoi organizzare.")
                Text("2. In Seleziona, indica almeno 5 foto che ti piacciono e 5 che non fanno per te. Salva le preferenze, anche prima di arrivare a 10.")
                Text("3. Rivedi i consigli: conferma, correggi o proteggi i ricordi importanti.")
            }
            Section("Cosa insegno al modello?") {
                Text("Mi piace e Non rispecchia il mio gusto aggiornano le preferenze estetiche. Duplicati, appunti inutili e ricordi importanti sono decisioni organizzative: non insegnano che una foto sia bella o brutta.")
                Text("Durante la selezione l’app dà priorità alle foto incerte tra quelle già caricate, mantenendo anche scatti esplorativi. Più esempi diversi aiutano a personalizzare i consigli.")
            }
            Section("Eliminazione e recupero") {
                Text("La selezione non elimina nulla. Devi confermare nell’app e nel pannello di Foto. Le modifiche si sincronizzano con iCloud, se attivo.")
                Text("Per recuperare una foto, apri Eliminati di recente nell’app Foto. Disponibilità e scadenza del recupero sono gestite da Apple.")
                Text("I preferiti di Foto e i ricordi protetti non possono essere eliminati da GallerIA. Nei gruppi noti di foto simili viene conservato almeno uno scatto disponibile.")
            }
            Section("iCloud e accesso limitato") {
                Text("L’analisi automatica usa immagini disponibili sul dispositivo. Aprire un’anteprima può scaricare una foto da iCloud. I limiti di scansione sono indicati nelle schermate: l’app non analizza sempre tutta la libreria.")
                Text("Puoi cambiare le foto accessibili nelle Impostazioni di iOS. Con accesso limitato, i consigli riguardano soltanto le foto autorizzate.")
            }
            Section("Acquisti") {
                Text("Pro è un acquisto singolo per gli strumenti di pulizia. La selezione personale e la protezione dei ricordi restano disponibili senza Pro. Per recuperare Pro usa Ripristina acquisti con lo stesso account Apple.")
            }
            Section("Assistenza") {
                if let url = ReleaseConfiguration.supportURL { Link("Contatta l’assistenza", destination: url) }
                else { Text("Per domande sull’acquisto puoi usare il collegamento Assistenza app nella pagina di GallerIA su App Store, quando disponibile.") }
                if let url = ReleaseConfiguration.privacyURL { Link("Informativa privacy", destination: url) }
                Link("Condizioni d’uso Apple", destination: ReleaseConfiguration.termsURL)
                LabeledContent("Versione", value: ReleaseConfiguration.version)
            }
        }.navigationTitle("Guida e assistenza")
    }
}

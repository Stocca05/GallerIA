import SwiftUI
import MapKit
import Photos

struct MapMasterpieceView: View {
    let goodAssets: [ScoredAsset]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Mappa Capolavori (In sviluppo)")
                    .font(.title)
                    .padding()
            }
            .navigationTitle("Mappa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}

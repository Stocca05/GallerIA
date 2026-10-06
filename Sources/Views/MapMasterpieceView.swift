import SwiftUI
import MapKit

struct MapMasterpieceView: View {
    let goodAssets: [ScoredAsset]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: String?
    @State private var photo: ScoredAsset?

    var body: some View {
        NavigationStack {
            Map(selection: $selectedID) {
                ForEach(goodAssets) { item in
                    if let location = item.asset.location {
                        Marker(item.asset.creationDate?.formatted(date: .abbreviated, time: .omitted) ?? "Foto",
                               systemImage: "photo", coordinate: location.coordinate)
                            .tint(GalleryStyle.accent).tag(item.id)
                    }
                }
            }
            .mapControls { MapCompass(); MapScaleView() }
            .safeAreaInset(edge: .bottom) {
                Text("Sono mostrate solo le foto della raccolta con una posizione registrata.")
                    .font(.caption).padding().frame(maxWidth: .infinity).background(.regularMaterial)
            }
            .navigationTitle("I luoghi dei tuoi ricordi").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Chiudi") { dismiss() } } }
            .onChange(of: selectedID) { _, id in photo = goodAssets.first { $0.id == id } }
            .sheet(item: $photo, onDismiss: { selectedID = nil }) {
                PhotoDetailView(image: $0.image, score: $0.score, asset: $0.asset)
            }
        }.tint(GalleryStyle.accent).preferredColorScheme(.dark)
    }
}

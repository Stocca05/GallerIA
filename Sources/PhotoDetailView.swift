import SwiftUI

struct PhotoDetailView: View {
    let image: UIImage
    let score: Float
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding()
                    .shadow(radius: 10)
                
                VStack(spacing: 12) {
                    Text("Analisi Neurale")
                        .font(.title2.bold())
                    
                    HStack {
                        Text("Affinità Estetica:")
                        Spacer()
                        Text("\(Int(score * 100))%")
                            .bold()
                            .foregroundColor(score >= 0.8 ? .green : .orange)
                    }
                    
                    ProgressView(value: score, total: 1.0)
                        .tint(score >= 0.8 ? .green : .orange)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Dettaglio")
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

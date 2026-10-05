import SwiftUI

struct ContentView: View {
    @State private var aestheticScore: Double = 0.88

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.yellow)

            Text("Estetica")
                .font(.headline)

            ZStack {
                Circle()
                    .stroke(lineWidth: 10)
                    .opacity(0.3)
                    .foregroundColor(.purple)

                Circle()
                    .trim(from: 0.0, to: CGFloat(min(aestheticScore, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.cyan)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: aestheticScore)

                Text(String(format: "%.0f%%", min(aestheticScore, 1.0) * 100.0))
                    .font(.title3.bold())
            }
            .padding()

            Button("Allenati") {
                aestheticScore = min(aestheticScore + 0.02, 1.0)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
    }
}

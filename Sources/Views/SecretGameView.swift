import SwiftUI
import Combine

struct SecretGameView: View {
    @State private var position: CGPoint = CGPoint(x: 200, y: 300)
    @State private var score: Int = 0
    @State private var timeLeft: Int = 15
    @State private var isPlaying: Bool = true

    @Environment(\.dismiss) private var dismiss
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .purple.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Text("Punteggio Sviluppatore: \(score)")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text("Tempo: \(timeLeft)s")
                        .font(.headline.monospacedDigit())
                        .foregroundColor(timeLeft <= 5 ? .red : .white)
                }
                .padding()

                Spacer()

                if !isPlaying {
                    VStack(spacing: 20) {
                        Text("Game Over!")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Text("Hai catturato l'intelligenza artificiale \(score) volte.")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Esci dal Matrix") {
                            dismiss()
                        }
                        .padding()
                        .background(Color.cyan, in: Capsule())
                        .foregroundColor(.black)
                        .font(.headline.bold())
                    }
                    .glassmorphism(cornerRadius: 24, borderOpacity: 0.3)
                    .padding()
                }

                Spacer()
            }

            if isPlaying {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan, radius: 10)
                    .position(position)
                    .onTapGesture {
                        SoundManager.shared.playSuccess()
                        let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                        impactHeavy.impactOccurred()
                        score += 1
                        moveBrain()
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: position)
            }
        }
        .onReceive(timer) { _ in
            if isPlaying {
                if timeLeft > 0 {
                    timeLeft -= 1
                    if timeLeft % 2 == 0 {
                        moveBrain()
                    }
                } else {
                    isPlaying = false
                    SoundManager.shared.playDelete()
                }
            }
        }
        .onAppear {
            moveBrain()
        }
    }

    private func moveBrain() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        let randomX = CGFloat.random(in: 50...(screenWidth - 50))
        let randomY = CGFloat.random(in: 150...(screenHeight - 150))

        position = CGPoint(x: randomX, y: randomY)
    }
}

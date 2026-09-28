import SwiftUI

struct MainSwipingView: View {
    let currentImage: UIImage
    let currentScore: Float
    let rateAction: (Bool) -> Void
    
    var body: some View {
        ZStack {
            Image(uiImage: currentImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: 50)
                .opacity(0.6)

            VStack {
                Text("Score: \(Int(currentScore * 100))%")
                    .font(.title.bold())
                    .foregroundColor(currentScore >= 0.5 ? .green : .red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.45))
                    .cornerRadius(16)

                CardView(image: currentImage, score: currentScore) { liked in
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                    rateAction(liked)
                }
                .id(currentImage)
            }
            .padding()
            
            if currentScore >= 0.9 {
                ConfettiView().allowsHitTesting(false)
            }
        }
    }
}

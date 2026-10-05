import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private var player: AVAudioPlayer?

    private init() {}

    func playSound(named name: String, ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
        }
    }

    func playSwipeRight() {
        // Fallback to system sounds if no custom sound
        AudioServicesPlaySystemSound(1104)
    }

    func playSwipeLeft() {
        AudioServicesPlaySystemSound(1105)
    }

    func playSuccess() {
        AudioServicesPlaySystemSound(1001) // Appreciate sound
    }

    func playDelete() {
        AudioServicesPlaySystemSound(1030) // Trash sound
    }
}

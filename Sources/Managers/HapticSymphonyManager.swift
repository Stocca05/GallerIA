import CoreHaptics
import SwiftUI

class HapticSymphonyManager {
    static let shared = HapticSymphonyManager()

    private var engine: CHHapticEngine?

    private init() {
        prepareHaptics()
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }

    func playScanningSymphony() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()

        // Create a rhythmic pattern mimicking an AI heartbeat or processing pulse
        for i in stride(from: 0, to: 1.5, by: 0.15) {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(1.5 - i))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(i))
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: i)
            events.append(event)
        }

        // Final heavy thud
        let heavyIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let heavySharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let finalEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [heavyIntensity, heavySharpness], relativeTime: 1.6)
        events.append(finalEvent)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }

    func playSuccessRipple() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()

        // A satisfying fast triple ripple
        for i in stride(from: 0, to: 0.3, by: 0.1) {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: i)
            events.append(event)
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play ripple pattern: \(error.localizedDescription).")
        }
    }
}

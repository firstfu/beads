import CoreHaptics
import UIKit

final class HapticService {
    private var engine: CHHapticEngine?
    var isEnabled: Bool = true

    init() {
        setupEngine()
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            print("Haptic engine error: \(error)")
        }
    }

    func playBeadTap() {
        guard isEnabled else { return }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func playRoundComplete() {
        guard isEnabled else { return }
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics, let engine else {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            return
        }

        do {
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)

            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.15)
            let event3 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.3)

            let pattern = try CHHapticPattern(events: [event1, event2, event3], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic pattern error: \(error)")
        }
    }
}

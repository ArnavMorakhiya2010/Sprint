import UIKit

enum HapticsManager {
    /// One click per minute crossed while dragging the arc dial.
    static func arcTick() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Fired once per second during the 5-second grace period before a session locks in.
    static func countdownTick() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// The Haptic Anchor — a subtle double-tap every 10 minutes of a running session.
    static func anchorPulse() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generator.impactOccurred()
        }
    }

    static func forfeit() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// A strong, celebratory sequence for finishing a full session: the system success
    /// chime immediately, followed by two heavy impact pulses landing just after it.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { impact.impactOccurred() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) { impact.impactOccurred(intensity: 0.8) }
    }

    /// The splash screen's "impact" beat — a sharp, heavy pulse landing with the
    /// resolving chord in `LaunchSoundPlayer`.
    static func launchSettle() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            generator.impactOccurred(intensity: 0.6)
        }
    }
}

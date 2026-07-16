import UIKit

enum HapticsManager {
    /// One click per minute crossed while dragging the arc dial.
    static func arcTick() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Fired once per second during the 5-second face-down grace period.
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

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

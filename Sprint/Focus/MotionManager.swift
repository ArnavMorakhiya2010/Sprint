import Foundation
import CoreMotion
import Combine

/// Watches the device's gravity vector to detect whether it's propped up leaning — e.g.
/// against a wall or a stack of books — in landscape, screen visible to the user. This is
/// the enforcement mechanism behind the Focus Engine's forfeit rule: pick the phone up to
/// text or scroll and `isLeaning` drops, which the engine treats as an instant failure.
///
/// Raw accelerometer / device-motion streaming does not require an
/// `NSMotionUsageDescription` entry (that key only gates `CMMotionActivityManager` /
/// `CMPedometer`), so no Info.plist permission string is needed for this.
final class MotionManager: ObservableObject {
    @Published private(set) var isLeaning = false

    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 0.2

    /// Landscape check: UIKit itself infers landscape from the accelerometer by comparing
    /// the magnitude of gravity's x and y components in the device's own frame — when the
    /// device is rotated 90° onto its side, gravity shows up mostly on x instead of y.
    private let landscapeXThreshold = 0.6
    private let landscapeYThreshold = 0.5

    /// Leaning check: gravity.z is the screen-normal component. Near ±1 means the phone is
    /// lying flat (screen up or down); near 0 means it's held bolt upright, perpendicular
    /// to gravity. A propped, reclined "leaning against something" posture sits in between.
    /// Tune on a physical device — this hasn't been hardware-verified in this environment.
    private let leaningZRange: ClosedRange<Double> = 0.2...0.85

    func startMonitoring() {
        #if targetEnvironment(simulator)
        // The Simulator has no CoreMotion hardware at all, so `isDeviceMotionAvailable`
        // is always false there — without this, the leaning check could never pass and
        // every session would time out during the 5-second grace period, Simulator only.
        // Bypassing it here doesn't weaken real enforcement: Simulator builds never ship,
        // and the `#else` branch (full device-motion check) is what runs on an actual
        // iPhone regardless of how the app was built.
        isLeaning = true
        #else
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let g = motion.gravity
            let isLandscape = abs(g.x) > self.landscapeXThreshold && abs(g.y) < self.landscapeYThreshold
            let isInclined = self.leaningZRange.contains(abs(g.z))
            self.isLeaning = isLandscape && isInclined
        }
        #endif
    }

    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        isLeaning = false
    }
}

import Foundation
import CoreMotion
import Combine

enum DeviceFacing {
    case faceUp
    case faceDown
    case unknown
}

/// Watches the device's gravity vector to detect whether the phone is resting face down,
/// which is the enforcement mechanism behind the Face-Down Forfeit. Raw accelerometer /
/// device-motion streaming does not require an `NSMotionUsageDescription` entry (that key
/// only gates `CMMotionActivityManager` / `CMPedometer`), so no Info.plist permission
/// string is needed for this.
final class MotionManager: ObservableObject {
    @Published private(set) var facing: DeviceFacing = .unknown

    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 0.2

    /// Gravity's z-component reads ~+1 g when the phone lies screen-down on a flat
    /// surface and ~-1 g when it lies screen-up. This threshold was chosen to tolerate
    /// a slight tilt without false-triggering a forfeit; confirm on a physical device
    /// and adjust if a particular case/surface throws it off.
    private let faceDownThreshold = 0.75

    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let z = motion.gravity.z
            if z > self.faceDownThreshold {
                self.facing = .faceDown
            } else if z < -self.faceDownThreshold {
                self.facing = .faceUp
            } else {
                self.facing = .unknown
            }
        }
    }

    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        facing = .unknown
    }
}

import SwiftUI
import Combine

/// Publishes whether the device is currently held in a landscape interface orientation.
/// `ContentView` uses this to swap between the portrait Home stub and the landscape
/// Focus Engine — the entire "turn the phone to enter Focus Mode" interaction hinges on it.
final class OrientationObserver: ObservableObject {
    @Published var isLandscape: Bool

    private var cancellable: AnyCancellable?

    init() {
        isLandscape = UIDevice.current.orientation.isLandscape

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        cancellable = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                let orientation = UIDevice.current.orientation
                // Ignore face-up/face-down/unknown reports — those aren't interface
                // orientations and would otherwise stomp the last known good state.
                guard orientation != .faceUp, orientation != .faceDown, orientation != .unknown else { return }
                self?.isLandscape = orientation.isLandscape
            }
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}

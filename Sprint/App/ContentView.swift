import SwiftUI

struct ContentView: View {
    @StateObject private var orientationObserver = OrientationObserver()

    var body: some View {
        Group {
            if orientationObserver.isLandscape {
                LandscapeArcTimerView()
            } else {
                HomeStubView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: orientationObserver.isLandscape)
    }
}

import SwiftUI

/// App entry flow: splash plays on every launch, then either Onboarding (first run) or
/// the tabbed `MainTabView`, depending on `hasCompletedOnboarding`.
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView(onFinished: { showSplash = false })
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
    }
}

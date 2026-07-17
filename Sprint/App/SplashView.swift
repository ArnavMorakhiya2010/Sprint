import SwiftUI

/// Shown every time the app opens (not just first launch). A short, haptic-synced reveal
/// meant to make opening the app itself feel deliberate rather than throwaway.
///
/// Kept the "Sprint" name on the wordmark — the reference design system's own branding
/// ("Pomly"/"Pom") was adopted for the visual language (palette, type, mascot concept),
/// not as a product rename, since that wasn't explicitly asked for.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var mascotScale: CGFloat = 0.6
    @State private var mascotOpacity: Double = 0
    @State private var wordmarkOpacity: Double = 0
    @State private var underlineWidth: CGFloat = 0

    var body: some View {
        ZStack {
            Color.theme.cream.ignoresSafeArea()

            VStack(spacing: 18) {
                PomMascotView(pose: .idle, size: 96)
                    .scaleEffect(mascotScale)
                    .opacity(mascotOpacity)

                VStack(spacing: 10) {
                    Text("SPRINT")
                        .font(.theme.h1Large())
                        .foregroundStyle(Color.theme.espresso)
                        .tracking(3)

                    Rectangle()
                        .fill(Color.theme.orange)
                        .frame(width: underlineWidth, height: 4)
                        .clipShape(Capsule())
                }
                .opacity(wordmarkOpacity)
            }
        }
        .task {
            await runSequence()
        }
    }

    private func runSequence() async {
        HapticsManager.launchTick()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) {
            mascotScale = 1
            mascotOpacity = 1
        }

        try? await Task.sleep(nanoseconds: 300_000_000)
        HapticsManager.launchTick()
        withAnimation(.easeOut(duration: 0.35)) {
            wordmarkOpacity = 1
            underlineWidth = 110
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        HapticsManager.launchSettle()

        try? await Task.sleep(nanoseconds: 500_000_000)
        onFinished()
    }
}

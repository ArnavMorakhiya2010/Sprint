import SwiftUI

/// A Netflix-style opening: a rising sound builds tension while Pom and a glow scale up,
/// then everything lands on a sharp "impact" beat — a spring pop, a brief flash, and a
/// resolving chord — before settling into the wordmark. Shown on every app open, not just
/// first launch.
///
/// Kept the "Sprint" name on the wordmark — the reference design system's own branding
/// ("Pomly"/"Pom") was adopted for the visual language (palette, type, mascot concept),
/// not as a product rename, since that wasn't explicitly asked for.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var mascotScale: CGFloat = 0.1
    @State private var mascotOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.3
    @State private var glowOpacity: Double = 0
    @State private var wordmarkOpacity: Double = 0
    @State private var flashOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.theme.charcoal.ignoresSafeArea()

            Circle()
                .fill(RadialGradient(colors: [Color.theme.orange.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: 220))
                .frame(width: 320, height: 320)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)

            VStack(spacing: 16) {
                PomMascotView(pose: .idle, size: 110)
                    .scaleEffect(mascotScale)
                    .opacity(mascotOpacity)

                Text("SPRINT")
                    .font(.theme.h1Large())
                    .foregroundStyle(Color.theme.cream)
                    .tracking(4)
                    .opacity(wordmarkOpacity)
            }

            Color.theme.orange
                .ignoresSafeArea()
                .opacity(flashOpacity)
                .allowsHitTesting(false)
        }
        .task {
            await runSequence()
        }
    }

    private func runSequence() async {
        LaunchSoundPlayer.playLaunchSound()

        // Riser: a slow build synced to the rising sweep in the sound.
        withAnimation(.easeIn(duration: 0.55)) {
            mascotScale = 0.85
            mascotOpacity = 1
            glowScale = 1.0
            glowOpacity = 0.5
        }

        try? await Task.sleep(nanoseconds: 550_000_000)

        // Impact: a snappy pop, a flash, and haptics, all landing together with the
        // resolving chord.
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            mascotScale = 1.0
            glowScale = 1.6
            glowOpacity = 0
        }
        withAnimation(.easeOut(duration: 0.12)) {
            flashOpacity = 0.32
        }
        HapticsManager.launchSettle()

        try? await Task.sleep(nanoseconds: 140_000_000)
        withAnimation(.easeOut(duration: 0.3)) {
            flashOpacity = 0
            wordmarkOpacity = 1
        }

        try? await Task.sleep(nanoseconds: 700_000_000)
        onFinished()
    }
}

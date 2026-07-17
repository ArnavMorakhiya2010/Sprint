import SwiftUI

/// Shown every time the app opens (not just first launch). A short, haptic-synced reveal
/// meant to make opening the app itself feel deliberate rather than throwaway.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var wordmarkScale: CGFloat = 0.6
    @State private var wordmarkOpacity: Double = 0
    @State private var underlineWidth: CGFloat = 0

    var body: some View {
        ZStack {
            Color.theme.leather.ignoresSafeArea()

            VStack(spacing: 14) {
                Text("SPRINT")
                    .font(.theme.display(52))
                    .foregroundStyle(Color.theme.white)
                    .tracking(4)
                    .scaleEffect(wordmarkScale)
                    .opacity(wordmarkOpacity)

                Rectangle()
                    .fill(Color.theme.taupe)
                    .frame(width: underlineWidth, height: 4)
                    .clipShape(Capsule())
            }
        }
        .task {
            await runSequence()
        }
    }

    private func runSequence() async {
        HapticsManager.launchTick()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) {
            wordmarkScale = 1
            wordmarkOpacity = 1
        }

        try? await Task.sleep(nanoseconds: 350_000_000)
        HapticsManager.launchTick()
        withAnimation(.easeOut(duration: 0.4)) {
            underlineWidth = 130
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        HapticsManager.launchSettle()

        try? await Task.sleep(nanoseconds: 500_000_000)
        onFinished()
    }
}

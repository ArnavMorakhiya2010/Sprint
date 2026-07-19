import SwiftUI

/// The timer card from the reference: a dark rounded card, a thin gradient ring, Pom
/// perched right on the arc, and two small icon controls underneath instead of text
/// buttons. Used both as the idle preview on the Home tab and (implicitly, via the same
/// visual language) during an active session.
struct PomodoroCardView: View {
    let fraction: Double
    let timeText: String
    var showMascot: Bool = true
    var resetSystemImage: String = "arrow.counterclockwise"
    var editSystemImage: String = "pencil"
    var onReset: (() -> Void)?
    var onEdit: (() -> Void)?
    /// Non-nil makes the ring itself draggable to set a value — used on the Home tab to
    /// set the Pomodoro duration with the same card that later displays live progress.
    var onDrag: ((_ location: CGPoint, _ center: CGPoint) -> Void)?

    // A LinearGradient varies by on-screen position rather than by how much of the path
    // has been traced, so — unlike an AngularGradient here — it stays visibly a gradient
    // no matter how small a slice of the ring is currently filled. Two genuinely distinct
    // colors (not just opacity steps of the same one), matching the reference's
    // deep-to-bright orange sweep.
    private let ringGradient = LinearGradient(
        colors: [Color(hex: 0xC96A2E), Color.theme.orange],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )

    var body: some View {
        VStack(spacing: 22) {
            GeometryReader { geo in
                let ringLineWidth: CGFloat = 7
                let side = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                // Must match PomTimerRing's own internal radius formula exactly, or Pom
                // (positioned from out here) won't land on the ring drawn in there.
                let radius = side / 2 - ringLineWidth / 2 - 4

                ZStack {
                    PomTimerRing(
                        fraction: fraction,
                        ringStyle: ringGradient,
                        trackColor: Color.white.opacity(0.08),
                        lineWidth: ringLineWidth,
                        onDrag: onDrag
                    )

                    Text(timeText)
                        .font(.theme.timerDigits(side * 0.2))
                        .monospacedDigit()
                        .foregroundStyle(Color.theme.orange)
                        .rotationEffect(.degrees(-4))

                    if showMascot {
                        PomMascotView(pose: .idle, size: side * 0.16)
                            .position(PomTimerRing<Color>.position(on: center, radius: radius, fraction: fraction))
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, 28)
            .padding(.top, 28)

            HStack(spacing: 44) {
                cardIconButton(resetSystemImage, action: onReset)
                cardIconButton(editSystemImage, action: onEdit)
            }
            .padding(.bottom, 22)
        }
        .background(RoundedRectangle(cornerRadius: 32).fill(Color.theme.charcoal))
        .shadow(color: Color.theme.espresso.opacity(0.18), radius: 16, y: 8)
    }

    private func cardIconButton(_ systemImage: String, action: (() -> Void)?) -> some View {
        Button(action: { action?() }) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.white.opacity(0.08)))
        }
        .disabled(action == nil)
    }
}

import SwiftUI

/// The massive circular ring from the reference design: thin, starts at 12 o'clock, fills
/// clockwise. Runs in one of two modes:
/// - **Interactive** (`onDrag` non-nil): dragging anywhere around the ring sets a value —
///   used in `.configuring` to set the Pomodoro duration, replacing the old semicircle arc.
/// - **Passive**: `fraction` just reflects elapsed/remaining progress while a session runs;
///   nothing here reacts to touch.
///
/// Generic over `RingStyle` so callers can pass a flat `Color` or a gradient (the
/// reference's timer card uses a gradient sweep).
struct PomTimerRing<RingStyle: ShapeStyle>: View {
    let fraction: Double
    let ringStyle: RingStyle
    let trackColor: Color
    var lineWidth: CGFloat = 14
    var onDrag: ((_ location: CGPoint, _ center: CGPoint) -> Void)?

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = side / 2 - lineWidth / 2 - 4

            ZStack {
                Circle()
                    .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                Circle()
                    .trim(from: 0, to: max(0.0001, fraction))
                    .stroke(ringStyle, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                if onDrag != nil {
                    let point = Self.position(on: center, radius: radius, fraction: fraction)
                    Circle()
                        .fill(Color.theme.cream)
                        .frame(width: lineWidth * 1.7, height: lineWidth * 1.7)
                        .shadow(color: Color.theme.espresso.opacity(0.25), radius: 4, y: 2)
                        .position(point)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        onDrag?(value.location, center)
                    }
            )
        }
    }

    /// The point on the ring at a given fraction (0 = 12 o'clock, increasing clockwise) —
    /// exposed so callers can perch something (like Pom) directly on the arc.
    static func position(on center: CGPoint, radius: CGFloat, fraction: Double) -> CGPoint {
        let angle = (90 - fraction * 360) * Double.pi / 180
        return CGPoint(x: center.x + radius * cos(angle), y: center.y - radius * sin(angle))
    }

    /// Converts a touch location into a 0...1 fraction around the ring — the inverse of
    /// `position(on:radius:fraction:)`.
    static func resolvedFraction(for location: CGPoint, center: CGPoint) -> Double {
        let dx = location.x - center.x
        let dy = location.y - center.y
        let angleDegrees = atan2(-dy, dx) * 180 / .pi
        let raw = 90 - angleDegrees
        let wrapped = (raw.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return wrapped / 360
    }
}

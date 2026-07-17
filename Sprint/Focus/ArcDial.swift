import SwiftUI

/// A top-facing semicircle dial the user drags a finger along to set a duration, west
/// (minimum) to east (maximum) sweeping through north. Reports every drag update as an
/// absolute duration via `onChange`; `FocusEngine.setPlannedMinutes` is responsible for
/// only firing a haptic when the rounded minute value actually changes.
struct ArcDial: View {
    let minutes: Int
    let minMinutes: Int
    let maxMinutes: Int
    let onChange: (Int) -> Void

    private var fraction: Double {
        Double(minutes - minMinutes) / Double(maxMinutes - minMinutes)
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height)
            let radius = min(geo.size.width / 2 - 32, geo.size.height - 28)

            ZStack {
                ForEach(Array(stride(from: minMinutes, through: maxMinutes, by: 10)), id: \.self) { value in
                    tick(minuteValue: value, center: center, radius: radius)
                }

                strokedArc(to: 0.5, style: Color.theme.khaki.opacity(0.5), lineWidth: 16, center: center, radius: radius)

                // Soft glow sitting behind the crisp progress arc for a glassy, lit-up feel.
                strokedArc(to: 0.5 * fraction, style: Color.theme.taupe, lineWidth: 24, center: center, radius: radius)
                    .blur(radius: 14)
                    .opacity(0.45)

                strokedArc(
                    to: 0.5 * fraction,
                    style: LinearGradient(colors: [Color.theme.taupe, Color.theme.cacao], startPoint: .leading, endPoint: .trailing),
                    lineWidth: 16,
                    center: center,
                    radius: radius
                )

                knob(center: center, radius: radius)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        onChange(resolvedMinutes(for: value.location, center: center))
                    }
            )
        }
    }

    private func arcShape(to trimEnd: Double) -> some Shape {
        Circle()
            .trim(from: 0, to: trimEnd)
            .rotation(.degrees(180))
    }

    private func strokedArc<S: ShapeStyle>(to trimEnd: Double, style: S, lineWidth: CGFloat, center: CGPoint, radius: CGFloat) -> some View {
        arcShape(to: trimEnd)
            .stroke(style, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
    }

    private func tick(minuteValue: Int, center: CGPoint, radius: CGFloat) -> some View {
        let isMajor = minuteValue % 30 == 0
        let tickFraction = Double(minuteValue - minMinutes) / Double(maxMinutes - minMinutes)
        let angle = Double.pi * (1 - tickFraction)
        let tickRadius = radius + 18
        let x = center.x + tickRadius * cos(angle)
        let y = center.y - tickRadius * sin(angle)
        let size: CGFloat = isMajor ? 5 : 3

        return Circle()
            .fill(isMajor ? Color.theme.leather.opacity(0.45) : Color.theme.khaki)
            .frame(width: size, height: size)
            .position(x: x, y: y)
    }

    private func knob(center: CGPoint, radius: CGFloat) -> some View {
        let angle = Double.pi * (1 - fraction)
        let x = center.x + radius * cos(angle)
        let y = center.y - radius * sin(angle)

        return ZStack {
            Circle()
                .fill(Color.theme.white)
                .frame(width: 34, height: 34)
                .shadow(color: Color.theme.leather.opacity(0.35), radius: 6, y: 2)

            Circle()
                .stroke(Color.theme.taupe, lineWidth: 3)
                .frame(width: 34, height: 34)

            Circle()
                .fill(Color.theme.cacao)
                .frame(width: 10, height: 10)
        }
        .position(x: x, y: y)
    }

    /// Maps a touch location to a duration. Touches below the pivot's horizontal line
    /// (which falls outside the semicircle) snap to whichever extreme is nearer, so a
    /// finger dragging slightly below the dial doesn't jump erratically.
    private func resolvedMinutes(for location: CGPoint, center: CGPoint) -> Int {
        let dx = location.x - center.x
        let dy = location.y - center.y
        var angle = atan2(-dy, dx)
        if angle < 0 {
            angle = dx >= 0 ? 0 : .pi
        }
        let fraction = 1 - (angle / .pi)
        return Int((Double(minMinutes) + fraction * Double(maxMinutes - minMinutes)).rounded())
    }
}

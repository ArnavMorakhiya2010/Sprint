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
            let radius = min(geo.size.width / 2 - 24, geo.size.height - 20)

            ZStack {
                arc(to: 0.5, color: Color.theme.beige.opacity(0.25), center: center, radius: radius)
                arc(to: 0.5 * fraction, color: Color.theme.teal, center: center, radius: radius)
                    .shadow(color: Color.theme.teal.opacity(0.55), radius: 12)

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

    private func arc(to trimEnd: Double, color: Color, center: CGPoint, radius: CGFloat) -> some View {
        Circle()
            .trim(from: 0, to: trimEnd)
            .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
            .frame(width: radius * 2, height: radius * 2)
            .rotationEffect(.degrees(180))
            .position(center)
    }

    private func knob(center: CGPoint, radius: CGFloat) -> some View {
        let angle = Double.pi * (1 - fraction)
        let x = center.x + radius * cos(angle)
        let y = center.y - radius * sin(angle)
        return Circle()
            .fill(Color.theme.white)
            .frame(width: 28, height: 28)
            .shadow(radius: 4)
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

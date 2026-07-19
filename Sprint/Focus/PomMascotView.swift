import SwiftUI

enum PomPose: String {
    case idle
    case running
    case sleeping
    case celebrating

    /// Looked up as `pom_idle`, `pom_running`, etc. in the asset catalog.
    var assetName: String { "pom_\(rawValue)" }
}

/// Pomly's mascot, "Pom" — a round orange character with glasses and a leaf, used across
/// the app to reflect session state. This tool has no way to generate real illustrated
/// character art, so this looks for a bundled image first (drop real exports into
/// Assets.xcassets, named `pom_idle`/`pom_running`/`pom_sleeping`/`pom_celebrating`, to
/// use them) and otherwise falls back to a shape-built placeholder below — gradients,
/// a highlight, a grounding shadow, and per-pose touches (confetti, "Zzz", a running
/// lean), but still a geometric stand-in, not a reproduction of illustrated character art.
struct PomMascotView: View {
    let pose: PomPose
    var size: CGFloat = 96

    var body: some View {
        Group {
            if UIImage(named: pose.assetName) != nil {
                Image(pose.assetName)
                    .resizable()
                    .scaledToFit()
            } else {
                PomPlaceholder(pose: pose)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct PomPlaceholder: View {
    let pose: PomPose

    // Character-specific colors called out in the spec text itself ("green leaf",
    // "black glasses") — distinct from the app's own 4-color UI palette.
    private let leafGreen = Color(hex: 0x6FA86B)
    private let leafGreenDark = Color(hex: 0x4F8A4B)

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)

            ZStack {
                groundShadow(s: s)
                legs(s: s)
                limbs(s: s)
                torso(s: s)
                highlight(s: s)
                leaf(s: s)
                face(s: s)

                if pose == .celebrating {
                    confetti(s: s)
                }
                if pose == .sleeping {
                    zzz(s: s)
                }
            }
            .rotationEffect(.degrees(pose == .running ? -6 : 0))
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func groundShadow(s: CGFloat) -> some View {
        Ellipse()
            .fill(Color.theme.espresso.opacity(0.16))
            .frame(width: s * 0.6, height: s * 0.12)
            .offset(y: s * 0.56)
    }

    private func torso(s: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.theme.orange.opacity(0.92), Color(hex: 0xD9702E)],
                    center: UnitPoint(x: 0.35, y: 0.3),
                    startRadius: 0,
                    endRadius: s * 0.5
                )
            )
            .frame(width: s * 0.74, height: s * 0.74)
            .shadow(color: Color.theme.espresso.opacity(0.25), radius: s * 0.03, y: s * 0.02)
    }

    private func highlight(s: CGFloat) -> some View {
        Ellipse()
            .fill(Color.white.opacity(0.35))
            .frame(width: s * 0.2, height: s * 0.12)
            .rotationEffect(.degrees(-25))
            .offset(x: -s * 0.16, y: -s * 0.2)
    }

    private func leaf(s: CGFloat) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(leafGreenDark)
                .frame(width: max(1.5, s * 0.014), height: s * 0.06)
            Ellipse()
                .fill(LinearGradient(colors: [leafGreen, leafGreenDark], startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.15, height: s * 0.26)
                .rotationEffect(.degrees(-18))
        }
        .offset(y: -s * 0.42)
    }

    private func face(s: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.theme.espresso)
                .frame(width: s * 0.1, height: max(1, s * 0.016))

            HStack(spacing: s * 0.15) {
                eye(s: s)
                eye(s: s)
            }
        }
        .offset(y: -s * 0.02)
    }

    private func eye(s: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: s * 0.19, height: s * 0.19)
            Circle()
                .stroke(Color.theme.espresso, lineWidth: max(1.5, s * 0.022))
                .frame(width: s * 0.19, height: s * 0.19)

            if pose == .sleeping {
                Capsule()
                    .fill(Color.theme.espresso)
                    .frame(width: s * 0.11, height: max(1.5, s * 0.02))
            } else {
                Circle()
                    .fill(Color.theme.espresso)
                    .frame(width: s * 0.065, height: s * 0.065)
                Circle()
                    .fill(Color.white)
                    .frame(width: s * 0.02, height: s * 0.02)
                    .offset(x: -s * 0.015, y: -s * 0.015)
            }
        }
    }

    private func limbs(s: CGFloat) -> some View {
        let armAngle: Double = pose == .celebrating ? 55 : (pose == .running ? 25 : 68)
        return HStack {
            limb(s: s).rotationEffect(.degrees(armAngle))
            Spacer()
            limb(s: s).rotationEffect(.degrees(-armAngle))
        }
        .frame(width: s * 0.92)
        .offset(y: s * 0.06)
    }

    private func legs(s: CGFloat) -> some View {
        HStack(spacing: s * 0.16) {
            limb(s: s, length: 0.22).rotationEffect(.degrees(pose == .running ? -22 : 0))
            limb(s: s, length: 0.22).rotationEffect(.degrees(pose == .running ? 22 : 0))
        }
        .offset(y: s * 0.42)
    }

    private func limb(s: CGFloat, length: CGFloat = 0.28) -> some View {
        Capsule()
            .fill(LinearGradient(colors: [Color.theme.espresso, Color.theme.espresso.opacity(0.75)], startPoint: .top, endPoint: .bottom))
            .frame(width: max(2, s * 0.034), height: s * length)
    }

    private func confetti(s: CGFloat) -> some View {
        ZStack {
            confettiDot(s: s, color: Color.theme.orange, x: -0.3, y: -0.5)
            confettiDot(s: s, color: Color.theme.peach, x: 0.32, y: -0.55)
            confettiDot(s: s, color: leafGreen, x: -0.4, y: -0.28)
            confettiDot(s: s, color: Color.theme.orange, x: 0.4, y: -0.3)
        }
    }

    private func confettiDot(s: CGFloat, color: Color, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: s * 0.05, height: s * 0.05)
            .offset(x: s * x, y: s * y)
    }

    private func zzz(s: CGFloat) -> some View {
        Text("Zzz")
            .font(.system(size: s * 0.16, weight: .bold, design: .rounded))
            .foregroundStyle(Color.theme.espresso.opacity(0.5))
            .offset(x: s * 0.34, y: -s * 0.46)
    }
}

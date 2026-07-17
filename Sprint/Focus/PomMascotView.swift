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
/// use them) and otherwise falls back to a simple shape-built placeholder below — a rough
/// stand-in, not a reproduction of the reference illustrations.
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

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)

            ZStack {
                legs(s: s)
                limbs(s: s)

                Circle()
                    .fill(Color.theme.orange)
                    .frame(width: s * 0.72, height: s * 0.72)

                leaf(s: s)
                face(s: s)

                if pose == .celebrating {
                    Text("🎈")
                        .font(.system(size: s * 0.22))
                        .offset(x: s * 0.32, y: -s * 0.42)
                }
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func leaf(s: CGFloat) -> some View {
        Ellipse()
            .fill(leafGreen)
            .frame(width: s * 0.16, height: s * 0.28)
            .rotationEffect(.degrees(-20))
            .offset(y: -s * 0.4)
    }

    private func face(s: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.theme.espresso)
                .frame(width: s * 0.1, height: max(1, s * 0.015))

            HStack(spacing: s * 0.14) {
                eye(s: s)
                eye(s: s)
            }
        }
        .offset(y: -s * 0.02)
    }

    private func eye(s: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.theme.espresso, lineWidth: max(1.5, s * 0.02))
                .frame(width: s * 0.2, height: s * 0.2)

            if pose == .sleeping {
                Capsule()
                    .fill(Color.theme.espresso)
                    .frame(width: s * 0.12, height: max(1.5, s * 0.02))
            } else {
                Circle()
                    .fill(Color.theme.espresso)
                    .frame(width: s * 0.06, height: s * 0.06)
            }
        }
    }

    private func limbs(s: CGFloat) -> some View {
        let armAngle: Double = pose == .celebrating ? 50 : (pose == .running ? 20 : 70)
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
            limb(s: s, length: 0.22).rotationEffect(.degrees(pose == .running ? -18 : 0))
            limb(s: s, length: 0.22).rotationEffect(.degrees(pose == .running ? 18 : 0))
        }
        .offset(y: s * 0.42)
    }

    private func limb(s: CGFloat, length: CGFloat = 0.28) -> some View {
        Capsule()
            .fill(Color.theme.espresso)
            .frame(width: max(2, s * 0.032), height: s * length)
    }
}

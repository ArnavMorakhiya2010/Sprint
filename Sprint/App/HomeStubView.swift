import SwiftUI

/// Placeholder portrait root. Replaced by the real Home (Task Engine dashboard, tab bar,
/// etc.) in a later phase — for now it just exists so the app has somewhere to land when
/// the phone isn't in Focus Mode.
struct HomeStubView: View {
    var body: some View {
        ZStack {
            Color.theme.paper.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "rotate.right")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color.theme.marigold)

                Text("Rotate to Focus")
                    .font(.theme.header(24))
                    .foregroundStyle(Color.theme.ink)

                Text("Turn your phone horizontal to set up a locked-in Pomodoro session.")
                    .font(.theme.body(15))
                    .foregroundStyle(Color.theme.sand)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

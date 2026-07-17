import SwiftUI

/// Placeholder portrait root. Replaced by the real Home (Task Engine dashboard, tab bar,
/// etc.) in a later phase — for now it just exists so the app has somewhere to land when
/// the phone isn't in Focus Mode.
struct HomeStubView: View {
    var body: some View {
        ZStack {
            Color.theme.pearl.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "rotate.right")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color.theme.taupe)

                Text("Rotate to Focus")
                    .font(.theme.header(24))
                    .foregroundStyle(Color.theme.leather)

                Text("Turn your phone horizontal to set up a locked-in Pomodoro or FocusFlight session.")
                    .font(.theme.body(15))
                    .foregroundStyle(Color.theme.leather.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

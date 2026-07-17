import SwiftUI

/// Placeholder portrait root. Replaced by the real Home (Task Engine dashboard, tab bar,
/// etc.) in a later phase — for now it just exists so the app has somewhere to land when
/// the phone isn't in Focus Mode, and to host the Analytics dashboard until then.
struct HomeStubView: View {
    @State private var showingAnalytics = false

    var body: some View {
        ZStack {
            Color.theme.cream.ignoresSafeArea()

            VStack(spacing: 16) {
                PomMascotView(pose: .idle, size: 88)

                Text("Rotate to Focus")
                    .font(.theme.h1Small())
                    .foregroundStyle(Color.theme.espresso)

                Text("Turn your phone horizontal to set up a locked-in Pomodoro or FocusFlight session.")
                    .font(.theme.bodyMedium2())
                    .foregroundStyle(Color.theme.espresso.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button(action: { showingAnalytics = true }) {
                    Label("View Analytics", systemImage: "chart.bar.fill")
                        .font(.theme.button())
                        .foregroundStyle(Color.theme.cream)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.theme.orange))
                }
                .padding(.top, 12)
            }
        }
        .sheet(isPresented: $showingAnalytics) {
            AnalyticsView()
        }
    }
}

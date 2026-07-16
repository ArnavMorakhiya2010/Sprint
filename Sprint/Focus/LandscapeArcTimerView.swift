import SwiftUI
import SwiftData

/// The massive, landscape-only Pomodoro screen. Appears the moment the device is
/// rotated horizontal (see `ContentView`) and drives itself entirely off `FocusEngine`.
struct LandscapeArcTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var engine = FocusEngine()

    let subject: Subject?

    var body: some View {
        ZStack {
            Color.theme.ink.ignoresSafeArea()

            switch engine.phase {
            case .configuring:
                configuringView
            case .armed(let secondsLeft):
                armedView(secondsLeft: secondsLeft)
            case .running(let secondsLeft):
                runningView(secondsLeft: secondsLeft)
            case .forfeited:
                forfeitedView
            case .completed:
                completedView
            }
        }
        .persistentSystemOverlays(.hidden)
        .onAppear { engine.configure(context: modelContext, subject: subject) }
        .onDisappear { engine.reset() }
        .animation(.easeInOut(duration: 0.3), value: engine.phase)
    }

    // MARK: - Configuring

    private var configuringView: some View {
        VStack(spacing: 28) {
            Text((subject?.name ?? "GENERAL").uppercased())
                .font(.theme.caption())
                .foregroundStyle(Color.theme.sand)
                .tracking(2)

            Text(formatted(seconds: engine.plannedMinutes * 60))
                .font(.theme.timer(96))
                .monospacedDigit()
                .foregroundStyle(Color.theme.paper)

            ArcDial(
                minutes: engine.plannedMinutes,
                minMinutes: engine.minMinutes,
                maxMinutes: engine.maxMinutes,
                onChange: engine.setPlannedMinutes
            )
            .frame(height: 170)
            .padding(.horizontal, 48)

            Button(action: engine.start) {
                Text("START")
                    .font(.theme.header(18))
                    .foregroundStyle(Color.theme.ink)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.theme.marigold))
            }
        }
    }

    // MARK: - Armed (face-down grace period)

    private func armedView(secondsLeft: Int) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "iphone.gen3")
                .font(.system(size: 40))
                .foregroundStyle(Color.theme.marigold)
                .rotationEffect(.degrees(180))

            Text("FLIP IT FACE DOWN")
                .font(.theme.display(30))
                .foregroundStyle(Color.theme.paper)

            Text("\(secondsLeft)")
                .font(.theme.timer(120))
                .monospacedDigit()
                .foregroundStyle(Color.theme.marigold)

            Text("The session dies if you don't.")
                .font(.theme.body())
                .foregroundStyle(Color.theme.sand)
        }
    }

    // MARK: - Running

    private func runningView(secondsLeft: Int) -> some View {
        VStack(spacing: 16) {
            Text((subject?.name ?? "GENERAL").uppercased())
                .font(.theme.caption())
                .foregroundStyle(Color.theme.sand)
                .tracking(2)

            Text(formatted(seconds: secondsLeft))
                .font(.theme.timer(140))
                .monospacedDigit()
                .foregroundStyle(Color.theme.paper)

            Label("Locked \u{00B7} stay face down", systemImage: "lock.fill")
                .font(.theme.caption())
                .foregroundStyle(Color.theme.sand)
        }
    }

    // MARK: - Forfeited

    private var forfeitedView: some View {
        VStack(spacing: 20) {
            Text("SESSION FAILED")
                .font(.theme.display(36))
                .foregroundStyle(Color.theme.marigold)

            Text("You moved before time was up. No break earned.")
                .font(.theme.body())
                .foregroundStyle(Color.theme.sand)
                .multilineTextAlignment(.center)

            Button(action: engine.reset) {
                Text("BACK TO SETUP")
                    .font(.theme.header(16))
                    .foregroundStyle(Color.theme.paper)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 12)
                    .background(Capsule().stroke(Color.theme.sand, lineWidth: 1.5))
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Completed

    private var completedView: some View {
        VStack(spacing: 20) {
            Text("SESSION COMPLETE")
                .font(.theme.display(32))
                .foregroundStyle(Color.theme.moss)

            Text("\(engine.plannedMinutes) focused minutes, face down, no excuses.")
                .font(.theme.body())
                .foregroundStyle(Color.theme.sand)
                .multilineTextAlignment(.center)

            Button(action: engine.reset) {
                Text("DONE")
                    .font(.theme.header(16))
                    .foregroundStyle(Color.theme.ink)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.theme.moss))
            }
        }
        .padding(.horizontal, 40)
    }

    private func formatted(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

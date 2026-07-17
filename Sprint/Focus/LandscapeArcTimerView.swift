import SwiftUI
import SwiftData

/// The massive, landscape-only Focus Engine screen. Appears the moment the device is
/// rotated horizontal (see `ContentView`) and drives itself entirely off `FocusEngine`.
struct LandscapeArcTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var engine = FocusEngine()

    let subject: Subject?

    var body: some View {
        ZStack {
            Color.theme.navy

            switch engine.phase {
            case .configuring:
                configuringView
            case .armed(let secondsLeft):
                armedView(secondsLeft: secondsLeft)
            case .running(let secondsLeft):
                runningView(secondsLeft: secondsLeft)
            case .forfeited:
                forfeitedView
            case .audit:
                auditView
            case .cooldown(let secondsLeft):
                cooldownView(secondsLeft: secondsLeft)
            }
        }
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .onAppear { engine.configure(context: modelContext, subject: subject) }
        .onDisappear { engine.reset() }
        .onChange(of: scenePhase) { _, newPhase in
            engine.handleScenePhaseChange(newPhase)
        }
        .animation(.easeInOut(duration: 0.3), value: engine.phase)
    }

    // MARK: - Configuring

    private var configuringView: some View {
        GeometryReader { geo in
            let usableWidth = geo.size.width - geo.safeAreaInsets.leading - geo.safeAreaInsets.trailing
            let usableHeight = geo.size.height - geo.safeAreaInsets.top - geo.safeAreaInsets.bottom

            ZStack {
                ArcDial(
                    minutes: engine.plannedMinutes,
                    minMinutes: engine.minMinutes,
                    maxMinutes: engine.maxMinutes,
                    onChange: engine.setPlannedMinutes
                )
                .frame(width: usableWidth, height: usableHeight)

                VStack(spacing: 16) {
                    modeToggle
                        .padding(.top, 8)

                    Spacer()

                    if engine.selectedMode == .focusFlight {
                        flightPickers
                    } else {
                        Text((subject?.name ?? "GENERAL").uppercased())
                            .font(.theme.caption())
                            .foregroundStyle(Color.theme.beige)
                            .tracking(2)
                    }

                    Text(formatted(seconds: engine.plannedMinutes * 60))
                        .font(.theme.timer(84))
                        .monospacedDigit()
                        .foregroundStyle(Color.theme.white)

                    Spacer()

                    startButton
                        .padding(.bottom, 8)
                }
                .frame(width: usableWidth, height: usableHeight)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton(.pomodoro, label: "POMODORO")
            modeButton(.focusFlight, label: "FOCUSFLIGHT")
        }
        .padding(4)
        .background(Capsule().fill(Color.theme.white.opacity(0.08)))
    }

    private func modeButton(_ mode: SessionMode, label: String) -> some View {
        let isSelected = engine.selectedMode == mode
        return Button {
            engine.selectedMode = mode
        } label: {
            Text(label)
                .font(.theme.caption())
                .foregroundStyle(isSelected ? Color.theme.navy : Color.theme.beige)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? Color.theme.teal : Color.clear))
        }
    }

    private var flightPickers: some View {
        HStack(spacing: 16) {
            destinationChip(title: "DEPARTURE", selection: $engine.departure)
            Image(systemName: "airplane")
                .foregroundStyle(Color.theme.teal)
            destinationChip(title: "ARRIVAL", selection: $engine.arrival)
        }
    }

    private func destinationChip(title: String, selection: Binding<Destination?>) -> some View {
        Menu {
            ForEach(Destination.all) { destination in
                Button("\(destination.flag) \(destination.name)") {
                    selection.wrappedValue = destination
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.theme.caption(11))
                    .foregroundStyle(Color.theme.beige)
                Text(selection.wrappedValue.map { "\($0.flag) \($0.name)" } ?? "Select")
                    .font(.theme.header(16))
                    .foregroundStyle(Color.theme.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.theme.white.opacity(0.08)))
        }
    }

    private var startButton: some View {
        Button(action: engine.start) {
            Text(engine.selectedMode == .focusFlight ? "TAKE OFF" : "START")
                .font(.theme.header(18))
                .foregroundStyle(Color.theme.navy)
                .padding(.horizontal, 48)
                .padding(.vertical, 14)
                .background(Capsule().fill(engine.canStart ? Color.theme.teal : Color.theme.beige.opacity(0.35)))
        }
        .disabled(!engine.canStart)
    }

    // MARK: - Armed (leaning grace period, Pomodoro only)

    private func armedView(secondsLeft: Int) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "iphone.landscape")
                .font(.system(size: 40))
                .foregroundStyle(Color.theme.teal)

            Text("LEAN IT UP")
                .font(.theme.display(30))
                .foregroundStyle(Color.theme.white)

            Text("\(secondsLeft)")
                .font(.theme.timer(120))
                .monospacedDigit()
                .foregroundStyle(Color.theme.teal)

            Text("Prop it against something, landscape, screen visible.\nThe session dies if you don't.")
                .font(.theme.body())
                .foregroundStyle(Color.theme.beige)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Running

    private func runningView(secondsLeft: Int) -> some View {
        VStack(spacing: 16) {
            if engine.activeMode == .focusFlight {
                Text("\(engine.departure?.flag ?? "") \(engine.departure?.name ?? "?") \u{2192} \(engine.arrival?.flag ?? "") \(engine.arrival?.name ?? "?")".uppercased())
                    .font(.theme.caption())
                    .foregroundStyle(Color.theme.beige)
                    .tracking(1)
            } else {
                Text((subject?.name ?? "GENERAL").uppercased())
                    .font(.theme.caption())
                    .foregroundStyle(Color.theme.beige)
                    .tracking(2)
            }

            Text(formatted(seconds: secondsLeft))
                .font(.theme.timer(140))
                .monospacedDigit()
                .foregroundStyle(Color.theme.white)

            Label(
                engine.activeMode == .focusFlight ? "In flight \u{00B7} stay in the app" : "Leaning \u{00B7} stay propped up",
                systemImage: engine.activeMode == .focusFlight ? "airplane" : "lock.fill"
            )
            .font(.theme.caption())
            .foregroundStyle(Color.theme.beige)
        }
    }

    // MARK: - Forfeited

    private var forfeitedView: some View {
        VStack(spacing: 20) {
            Text("SESSION FAILED")
                .font(.theme.display(36))
                .foregroundStyle(Color.theme.white)

            Text(engine.lastFailureReason)
                .font(.theme.body())
                .foregroundStyle(Color.theme.beige)
                .multilineTextAlignment(.center)

            Button(action: engine.reset) {
                Text("BACK TO SETUP")
                    .font(.theme.header(16))
                    .foregroundStyle(Color.theme.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 12)
                    .background(Capsule().stroke(Color.theme.beige, lineWidth: 1.5))
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Audit

    private var auditView: some View {
        VStack(spacing: 24) {
            Text("SESSION COMPLETE")
                .font(.theme.display(30))
                .foregroundStyle(Color.theme.teal)

            Text("How was your focus?")
                .font(.theme.body())
                .foregroundStyle(Color.theme.beige)

            HStack(spacing: 12) {
                ratingButton(.good, label: "GOOD")
                ratingButton(.average, label: "AVERAGE")
                ratingButton(.bad, label: "BAD")
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $engine.draftNotes)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Color.theme.white)
                    .padding(8)

                if engine.draftNotes.isEmpty {
                    Text("Notes on this session\u{2026}")
                        .font(.theme.body(14))
                        .foregroundStyle(Color.theme.beige.opacity(0.6))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 90)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.theme.white.opacity(0.08)))

            Button(action: engine.submitAudit) {
                Text("SUBMIT")
                    .font(.theme.header(16))
                    .foregroundStyle(Color.theme.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(engine.draftRating == nil ? Color.theme.beige.opacity(0.35) : Color.theme.teal))
            }
            .disabled(engine.draftRating == nil)
        }
        .padding(.horizontal, 48)
    }

    private func ratingButton(_ rating: FocusRating, label: String) -> some View {
        let isSelected = engine.draftRating == rating
        return Button {
            engine.draftRating = rating
        } label: {
            Text(label)
                .font(.theme.caption())
                .foregroundStyle(isSelected ? Color.theme.navy : Color.theme.beige)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(isSelected ? Color.theme.teal : Color.theme.white.opacity(0.1)))
        }
    }

    // MARK: - Cooldown

    private func cooldownView(secondsLeft: Int) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass")
                .font(.system(size: 36))
                .foregroundStyle(Color.theme.teal)

            Text("Stand up. Look at something far away.\nSystem cooling down.")
                .font(.theme.header(22))
                .foregroundStyle(Color.theme.white)
                .multilineTextAlignment(.center)

            Text(formatted(seconds: secondsLeft))
                .font(.theme.timer(56))
                .monospacedDigit()
                .foregroundStyle(Color.theme.beige)
        }
        .padding(.horizontal, 40)
    }

    private func formatted(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

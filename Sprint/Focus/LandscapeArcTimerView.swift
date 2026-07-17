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
            Color.theme.leather

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
                // Only relevant to Pomodoro — FocusFlight's duration isn't user-set, so
                // there's nothing for the dial to do in that mode.
                if engine.selectedMode == .pomodoro {
                    ArcDial(
                        minutes: engine.plannedMinutes,
                        minMinutes: engine.minMinutes,
                        maxMinutes: engine.maxMinutes,
                        onChange: engine.setPlannedMinutes
                    )
                    .frame(width: usableWidth, height: usableHeight)
                }

                VStack(spacing: 16) {
                    Spacer()

                    if engine.selectedMode == .focusFlight {
                        flightBoardingPass
                    } else {
                        Text((subject?.name ?? "GENERAL").uppercased())
                            .font(.theme.caption())
                            .foregroundStyle(Color.theme.khaki)
                            .tracking(2)

                        Text(formatted(seconds: engine.plannedMinutes * 60))
                            .font(.theme.timer(84))
                            .monospacedDigit()
                            .foregroundStyle(Color.theme.white)
                    }

                    Spacer()

                    // Under the dial/card, not competing with it for attention.
                    modeToggle

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
                .foregroundStyle(isSelected ? Color.theme.leather : Color.theme.khaki)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? Color.theme.taupe : Color.clear))
        }
    }

    // MARK: - FocusFlight boarding pass

    private var flightBoardingPass: some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                codeColumn(title: "DEPARTURE", selection: $engine.departure)

                VStack(spacing: 6) {
                    Image(systemName: "airplane")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.theme.taupe)
                    Rectangle()
                        .fill(Color.theme.khaki)
                        .frame(height: 1)
                }
                .frame(width: 56)

                codeColumn(title: "ARRIVAL", selection: $engine.arrival)
            }

            if let departure = engine.departure, let arrival = engine.arrival {
                HStack {
                    flightStat(title: "DURATION", value: FlightCalculator.durationLabel(from: departure, to: arrival), alignment: .leading)
                    Spacer()
                    flightStat(title: "DISTANCE", value: "\(Int(FlightCalculator.distanceKm(from: departure, to: arrival))) km", alignment: .trailing)
                }
            }

            barcode
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.theme.white))
        .frame(maxWidth: 360)
    }

    private func codeColumn(title: String, selection: Binding<Destination?>) -> some View {
        Menu {
            ForEach(Destination.all) { destination in
                Button("\(destination.flag) \(destination.name)") {
                    selection.wrappedValue = destination
                }
            }
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(.theme.caption(10))
                    .foregroundStyle(Color.theme.leather.opacity(0.5))
                Text(selection.wrappedValue?.code ?? "---")
                    .font(.theme.display(32))
                    .foregroundStyle(Color.theme.leather)
                Text(selection.wrappedValue?.name ?? "Select")
                    .font(.theme.body(12))
                    .foregroundStyle(Color.theme.taupe)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func flightStat(title: String, value: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.theme.caption(10))
                .foregroundStyle(Color.theme.leather.opacity(0.45))
            Text(value)
                .font(.theme.header(15))
                .foregroundStyle(Color.theme.leather)
        }
    }

    private var barcode: some View {
        HStack(spacing: 3) {
            ForEach(0..<28, id: \.self) { index in
                Rectangle()
                    .fill(Color.theme.leather)
                    .frame(width: barWidth(for: index))
            }
        }
        .frame(height: 32)
    }

    /// A fixed repeating pattern rather than randomized widths, so the barcode doesn't
    /// visibly reshuffle every time SwiftUI re-evaluates the view body.
    private func barWidth(for index: Int) -> CGFloat {
        let pattern: [CGFloat] = [2, 1, 3, 1, 1, 2, 3, 1, 2, 1]
        return pattern[index % pattern.count]
    }

    private var startButton: some View {
        Button(action: engine.start) {
            Text(engine.selectedMode == .focusFlight ? "CHECK IN" : "START")
                .font(.theme.header(18))
                .foregroundStyle(Color.theme.leather)
                .padding(.horizontal, 48)
                .padding(.vertical, 14)
                .background(Capsule().fill(engine.canStart ? Color.theme.taupe : Color.theme.khaki.opacity(0.35)))
        }
        .disabled(!engine.canStart)
    }

    // MARK: - Armed (leaning grace period, Pomodoro only)

    private func armedView(secondsLeft: Int) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "iphone.landscape")
                .font(.system(size: 40))
                .foregroundStyle(Color.theme.taupe)

            Text("LEAN IT UP")
                .font(.theme.display(30))
                .foregroundStyle(Color.theme.white)

            Text("\(secondsLeft)")
                .font(.theme.timer(120))
                .monospacedDigit()
                .foregroundStyle(Color.theme.taupe)

            Text("Prop it against something, landscape, screen visible.\nThe session dies if you don't.")
                .font(.theme.body())
                .foregroundStyle(Color.theme.khaki)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Running

    @ViewBuilder
    private func runningView(secondsLeft: Int) -> some View {
        if engine.activeMode == .focusFlight, let departure = engine.departure, let arrival = engine.arrival {
            let totalSeconds = max(engine.activeDurationSeconds, 1)
            let progress = min(max(1 - Double(secondsLeft) / Double(totalSeconds), 0), 1)
            let totalDistance = FlightCalculator.distanceKm(from: departure, to: arrival)
            let distanceRemaining = Int((totalDistance * (1 - progress)).rounded())

            FlightMapView(
                departure: departure,
                arrival: arrival,
                progress: progress,
                secondsLeft: secondsLeft,
                distanceRemainingKm: distanceRemaining
            )
        } else {
            pomodoroRunningView(secondsLeft: secondsLeft)
        }
    }

    private func pomodoroRunningView(secondsLeft: Int) -> some View {
        VStack(spacing: 16) {
            Text((subject?.name ?? "GENERAL").uppercased())
                .font(.theme.caption())
                .foregroundStyle(Color.theme.khaki)
                .tracking(2)

            Text(formatted(seconds: secondsLeft))
                .font(.theme.timer(140))
                .monospacedDigit()
                .foregroundStyle(Color.theme.white)

            Label("Leaning \u{00B7} stay propped up", systemImage: "lock.fill")
                .font(.theme.caption())
                .foregroundStyle(Color.theme.khaki)
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
                .foregroundStyle(Color.theme.khaki)
                .multilineTextAlignment(.center)

            Button(action: engine.reset) {
                Text("BACK TO SETUP")
                    .font(.theme.header(16))
                    .foregroundStyle(Color.theme.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 12)
                    .background(Capsule().stroke(Color.theme.khaki, lineWidth: 1.5))
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Audit

    private var auditView: some View {
        VStack(spacing: 24) {
            Text("SESSION COMPLETE")
                .font(.theme.display(30))
                .foregroundStyle(Color.theme.taupe)

            Text("How was your focus?")
                .font(.theme.body())
                .foregroundStyle(Color.theme.khaki)

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
                        .foregroundStyle(Color.theme.khaki.opacity(0.6))
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
                    .foregroundStyle(Color.theme.leather)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(engine.draftRating == nil ? Color.theme.khaki.opacity(0.35) : Color.theme.taupe))
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
                .foregroundStyle(isSelected ? Color.theme.leather : Color.theme.khaki)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(isSelected ? Color.theme.taupe : Color.theme.white.opacity(0.1)))
        }
    }

    // MARK: - Cooldown

    private func cooldownView(secondsLeft: Int) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass")
                .font(.system(size: 36))
                .foregroundStyle(Color.theme.taupe)

            Text("Stand up. Look at something far away.\nSystem cooling down.")
                .font(.theme.header(22))
                .foregroundStyle(Color.theme.white)
                .multilineTextAlignment(.center)

            Text(formatted(seconds: secondsLeft))
                .font(.theme.timer(56))
                .monospacedDigit()
                .foregroundStyle(Color.theme.khaki)
        }
        .padding(.horizontal, 40)
    }

    private func formatted(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

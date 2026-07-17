import SwiftUI
import SwiftData

/// The massive, landscape-only Focus Engine screen. Appears the moment the device is
/// rotated horizontal (see `ContentView`) and drives itself entirely off `FocusEngine`.
///
/// Background follows the spec's "Dark Mode Focus State": cream/light everywhere except
/// the two deep-focus phases (`armed`, `running`), which flip to charcoal with orange as
/// the sole high-contrast accent and the rest of the chrome — including the mascot —
/// faded away.
struct LandscapeArcTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @StateObject private var engine = FocusEngine()
    @StateObject private var soundscape = SoundscapePlayer()

    var body: some View {
        ZStack {
            backgroundColor

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
        .overlay(alignment: .topLeading) {
            soundscapeControl
                .padding(.top, 12)
                .padding(.leading, 16)
        }
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .onAppear { engine.configure(context: modelContext) }
        .onDisappear {
            engine.reset()
            soundscape.current = .off
        }
        .onChange(of: scenePhase) { _, newPhase in
            engine.handleScenePhaseChange(newPhase)
        }
        .animation(.easeInOut(duration: 0.3), value: engine.phase)
    }

    private var isDarkPhase: Bool {
        switch engine.phase {
        case .armed, .running: return true
        default: return false
        }
    }

    private var backgroundColor: Color {
        isDarkPhase ? Color.theme.charcoal : Color.theme.cream
    }

    private var dialFraction: Double {
        Double(engine.plannedMinutes - engine.minMinutes) / Double(engine.maxMinutes - engine.minMinutes)
    }

    private func runningFraction(secondsLeft: Int) -> Double {
        let total = max(engine.activeDurationSeconds, 1)
        return min(max(1 - Double(secondsLeft) / Double(total), 0), 1)
    }

    // MARK: - Soundscape

    private var soundscapeControl: some View {
        Menu {
            ForEach(Soundscape.allCases) { option in
                Button {
                    soundscape.current = option
                } label: {
                    Label(option.label, systemImage: option.systemImage)
                }
            }
        } label: {
            Image(systemName: soundscape.current.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isDarkPhase ? Color.theme.cream : Color.theme.espresso)
                .frame(width: 38, height: 38)
                .background(Circle().fill(isDarkPhase ? Color.theme.cream.opacity(0.15) : Color.theme.espresso.opacity(0.08)))
        }
    }

    // MARK: - Configuring

    private var configuringView: some View {
        GeometryReader { geo in
            let usableWidth = geo.size.width - geo.safeAreaInsets.leading - geo.safeAreaInsets.trailing
            let usableHeight = geo.size.height - geo.safeAreaInsets.top - geo.safeAreaInsets.bottom
            let ringSide = min(usableWidth, usableHeight) * 0.6

            VStack(spacing: 10) {
                Spacer()

                if engine.selectedMode == .pomodoro {
                    PomMascotView(pose: .idle, size: ringSide * 0.32)

                    subjectPicker

                    ZStack {
                        PomTimerRing(
                            fraction: dialFraction,
                            ringColor: Color.theme.orange,
                            trackColor: Color.theme.peach,
                            lineWidth: 14,
                            onDrag: { location, center in
                                let fraction = PomTimerRing.resolvedFraction(for: location, center: center)
                                let minutes = engine.minMinutes + Int((fraction * Double(engine.maxMinutes - engine.minMinutes)).rounded())
                                engine.setPlannedMinutes(minutes)
                            }
                        )
                        .frame(width: ringSide, height: ringSide)

                        Text(formatted(seconds: engine.plannedMinutes * 60))
                            .font(.theme.timerDigits(ringSide * 0.19))
                            .monospacedDigit()
                            .foregroundStyle(Color.theme.espresso)
                    }
                } else {
                    flightBoardingPass
                }

                Spacer()

                modeToggle
                startButton
                    .padding(.bottom, 8)
            }
            .frame(width: usableWidth, height: usableHeight)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var subjectPicker: some View {
        Menu {
            Button("General") { engine.selectedSubject = nil }
            ForEach(subjects) { subject in
                Button(subject.name) { engine.selectedSubject = subject }
            }
        } label: {
            HStack(spacing: 6) {
                Text((engine.selectedSubject?.name ?? "GENERAL").uppercased())
                    .font(.theme.bodySmall())
                    .foregroundStyle(Color.theme.espresso.opacity(0.6))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.theme.espresso.opacity(0.6))
            }
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton(.pomodoro, label: "POMODORO")
            modeButton(.focusFlight, label: "FOCUSFLIGHT")
        }
        .padding(4)
        .background(Capsule().fill(Color.theme.peach.opacity(0.4)))
    }

    private func modeButton(_ mode: SessionMode, label: String) -> some View {
        let isSelected = engine.selectedMode == mode
        return Button {
            engine.selectedMode = mode
        } label: {
            Text(label)
                .font(.theme.bodySmall())
                .foregroundStyle(isSelected ? Color.theme.cream : Color.theme.espresso.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? Color.theme.orange : Color.clear))
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
                        .foregroundStyle(Color.theme.orange)
                    Rectangle()
                        .fill(Color.theme.peach)
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
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
        .shadow(color: Color.theme.espresso.opacity(0.1), radius: 12, y: 6)
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
                    .font(.theme.bodySmall())
                    .foregroundStyle(Color.theme.espresso.opacity(0.5))
                Text(selection.wrappedValue?.code ?? "---")
                    .font(.theme.h1Small())
                    .foregroundStyle(Color.theme.espresso)
                Text(selection.wrappedValue?.name ?? "Select")
                    .font(.theme.bodyMedium2())
                    .foregroundStyle(Color.theme.orange)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func flightStat(title: String, value: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.theme.bodySmall())
                .foregroundStyle(Color.theme.espresso.opacity(0.45))
            Text(value)
                .font(.theme.h3())
                .foregroundStyle(Color.theme.espresso)
        }
    }

    private var barcode: some View {
        HStack(spacing: 3) {
            ForEach(0..<28, id: \.self) { index in
                Rectangle()
                    .fill(Color.theme.espresso)
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
                .font(.theme.button())
                .foregroundStyle(Color.theme.cream)
                .padding(.horizontal, 48)
                .padding(.vertical, 14)
                .background(Capsule().fill(engine.canStart ? Color.theme.orange : Color.theme.peach))
        }
        .disabled(!engine.canStart)
    }

    // MARK: - Armed (leaning grace period, Pomodoro only) — deep-focus dark mode

    private func armedView(secondsLeft: Int) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "iphone.landscape")
                .font(.system(size: 40))
                .foregroundStyle(Color.theme.orange)

            Text("LEAN IT UP")
                .font(.theme.h1Small())
                .foregroundStyle(Color.theme.cream)

            Text("\(secondsLeft)")
                .font(.theme.timerDigits(96))
                .monospacedDigit()
                .foregroundStyle(Color.theme.orange)

            Text("Prop it against something, landscape, screen visible.\nThe session dies if you don't.")
                .font(.theme.bodyMedium2())
                .foregroundStyle(Color.theme.cream.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Running — deep-focus dark mode

    @ViewBuilder
    private func runningView(secondsLeft: Int) -> some View {
        if engine.activeMode == .focusFlight, let departure = engine.departure, let arrival = engine.arrival {
            let progress = runningFraction(secondsLeft: secondsLeft)
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
        GeometryReader { geo in
            let usableWidth = geo.size.width - geo.safeAreaInsets.leading - geo.safeAreaInsets.trailing
            let usableHeight = geo.size.height - geo.safeAreaInsets.top - geo.safeAreaInsets.bottom
            let ringSide = min(usableWidth, usableHeight) * 0.72

            VStack {
                Spacer()

                ZStack {
                    PomTimerRing(
                        fraction: runningFraction(secondsLeft: secondsLeft),
                        ringColor: Color.theme.orange,
                        trackColor: Color.theme.orange.opacity(0.18),
                        lineWidth: 14
                    )
                    .frame(width: ringSide, height: ringSide)

                    VStack(spacing: 8) {
                        Text(formatted(seconds: secondsLeft))
                            .font(.theme.timerDigits(ringSide * 0.22))
                            .monospacedDigit()
                            .foregroundStyle(Color.theme.orange)

                        Text((engine.selectedSubject?.name ?? "GENERAL").uppercased())
                            .font(.theme.bodySmall())
                            .foregroundStyle(Color.theme.orange.opacity(0.7))
                    }
                }

                Spacer()
            }
            .frame(width: usableWidth, height: usableHeight)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Forfeited

    private var forfeitedView: some View {
        VStack(spacing: 20) {
            Text("SESSION FAILED")
                .font(.theme.h1Small())
                .foregroundStyle(Color.theme.espresso)

            Text(engine.lastFailureReason)
                .font(.theme.bodyMedium2())
                .foregroundStyle(Color.theme.espresso.opacity(0.6))
                .multilineTextAlignment(.center)

            Button(action: engine.reset) {
                Text("BACK TO SETUP")
                    .font(.theme.button())
                    .foregroundStyle(Color.theme.cream)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.theme.espresso))
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Audit

    private var auditView: some View {
        VStack(spacing: 20) {
            PomMascotView(pose: .celebrating, size: 76)

            Text("SESSION COMPLETE")
                .font(.theme.h1Small())
                .foregroundStyle(Color.theme.orange)

            Text("How was your focus?")
                .font(.theme.bodyMedium2())
                .foregroundStyle(Color.theme.espresso.opacity(0.6))

            HStack(spacing: 12) {
                ratingButton(.good, label: "GOOD")
                ratingButton(.average, label: "AVERAGE")
                ratingButton(.bad, label: "BAD")
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $engine.draftNotes)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Color.theme.espresso)
                    .padding(8)

                if engine.draftNotes.isEmpty {
                    Text("Notes on this session\u{2026}")
                        .font(.theme.bodyMedium2())
                        .foregroundStyle(Color.theme.espresso.opacity(0.4))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 80)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))

            Button(action: engine.submitAudit) {
                Text("SUBMIT")
                    .font(.theme.button())
                    .foregroundStyle(Color.theme.cream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(engine.draftRating == nil ? Color.theme.peach : Color.theme.orange))
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
                .font(.theme.bodySmall())
                .foregroundStyle(isSelected ? Color.theme.cream : Color.theme.espresso.opacity(0.6))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(isSelected ? Color.theme.orange : Color.white))
        }
    }

    // MARK: - Cooldown — Pom "replaces the timer" and sleeps

    private func cooldownView(secondsLeft: Int) -> some View {
        VStack(spacing: 16) {
            PomMascotView(pose: .sleeping, size: 96)

            Text("Stand up. Look at something far away.\nSystem cooling down.")
                .font(.theme.h3())
                .foregroundStyle(Color.theme.espresso)
                .multilineTextAlignment(.center)

            Text(formatted(seconds: secondsLeft))
                .font(.theme.timerDigits(44))
                .monospacedDigit()
                .foregroundStyle(Color.theme.orange)

            if !engine.cooldownActivities.isEmpty {
                VStack(spacing: 10) {
                    ForEach(Array(engine.cooldownActivities.enumerated()), id: \.offset) { _, activity in
                        Label(activity.text, systemImage: activity.systemImage)
                            .font(.theme.bodyMedium2())
                            .foregroundStyle(Color.theme.espresso)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                            .shadow(color: Color.theme.espresso.opacity(0.08), radius: 8, y: 4)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 40)
    }

    private func formatted(seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

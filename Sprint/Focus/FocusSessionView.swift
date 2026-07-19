import SwiftUI

/// The deep-focus full-screen cover, presented by `HomeTabView` once `engine.start()` is
/// called. Everything here follows the spec's "Dark Mode Focus State": charcoal
/// background, orange as the sole high-contrast accent, secondary chrome (including Pom)
/// hidden during `armed`/`running` so "the rest of the UI fades away to prevent
/// distractions." `configuring` itself lives on the Home tab now, not in this cover — the
/// leaning/landscape enforcement this cover exists for only applies once a session has
/// actually started.
struct FocusSessionView: View {
    @ObservedObject var engine: FocusEngine
    @EnvironmentObject private var soundscape: SoundscapePlayer
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            backgroundColor

            switch engine.phase {
            case .configuring:
                EmptyView()
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

    private func runningFraction(secondsLeft: Int) -> Double {
        let total = max(engine.activeDurationSeconds, 1)
        return min(max(1 - Double(secondsLeft) / Double(total), 0), 1)
    }

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
        .padding(.horizontal, 40)
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
        VStack(spacing: 16) {
            Text((engine.selectedSubject?.name ?? "GENERAL").uppercased())
                .font(.theme.bodySmall())
                .foregroundStyle(Color.theme.orange.opacity(0.7))

            PomodoroCardView(
                fraction: runningFraction(secondsLeft: secondsLeft),
                timeText: formatted(seconds: secondsLeft),
                showMascot: false
            )
            .frame(maxWidth: 320)

            Label("Leaning \u{00B7} stay propped up", systemImage: "lock.fill")
                .font(.theme.bodySmall())
                .foregroundStyle(Color.theme.orange.opacity(0.7))
        }
        .padding(.horizontal, 32)
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

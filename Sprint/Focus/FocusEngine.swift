import Foundation
import SwiftData
import Combine

enum FocusPhase: Equatable {
    /// Arc dial is live; user is dragging to set the duration.
    case configuring
    /// Start was tapped. `secondsLeft` counts down from 5 — the phone must go face down
    /// before this hits zero or the session forfeits before it even begins.
    case armed(secondsLeft: Int)
    /// Face down and counting down for real.
    case running(secondsLeft: Int)
    /// Picked up (or never placed down in time). Logged as a failure, no break earned.
    case forfeited
    /// Ran the full duration face down without interruption.
    case completed
}

/// Owns the Landscape Pomodoro state machine end to end: arc-drag configuration, the
/// 5-second face-down grace period, the running countdown with its 10-minute haptic
/// anchor, and the CoreMotion-driven forfeit rule. Every session — success or failure —
/// is written to SwiftData the moment it starts, then finalized on exit.
@MainActor
final class FocusEngine: ObservableObject {
    @Published private(set) var phase: FocusPhase = .configuring
    @Published private(set) var plannedMinutes: Int = 25

    let minMinutes = 5
    let maxMinutes = 120

    private let motionManager = MotionManager()
    private var armTimer: Timer?
    private var runTimer: Timer?
    private var secondsSinceLastAnchor = 0

    private let armGraceSeconds = 5
    private let anchorIntervalSeconds = 600

    private var modelContext: ModelContext?
    private var activeSubject: Subject?
    private var activeSession: FocusSession?

    func configure(context: ModelContext, subject: Subject?) {
        modelContext = context
        activeSubject = subject
    }

    /// Called continuously as the arc dial is dragged. Only fires a haptic tick when the
    /// rounded minute value actually changes, so a slow drag doesn't buzz continuously.
    func setPlannedMinutes(_ minutes: Int) {
        guard case .configuring = phase else { return }
        let clamped = max(minMinutes, min(maxMinutes, minutes))
        guard clamped != plannedMinutes else { return }
        plannedMinutes = clamped
        HapticsManager.arcTick()
    }

    func start() {
        guard case .configuring = phase, let modelContext else { return }

        let session = FocusSession(
            mode: .pomodoro,
            plannedDurationSeconds: plannedMinutes * 60,
            subject: activeSubject
        )
        modelContext.insert(session)
        activeSession = session

        motionManager.startMonitoring()
        beginArmingCountdown()
    }

    func reset() {
        armTimer?.invalidate()
        runTimer?.invalidate()
        motionManager.stopMonitoring()
        activeSession = nil
        plannedMinutes = 25
        phase = .configuring
    }

    private func beginArmingCountdown() {
        var secondsLeft = armGraceSeconds
        phase = .armed(secondsLeft: secondsLeft)

        armTimer?.invalidate()
        armTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { return }

                if self.motionManager.facing == .faceDown {
                    timer.invalidate()
                    self.beginRunning()
                    return
                }

                secondsLeft -= 1
                if secondsLeft <= 0 {
                    timer.invalidate()
                    self.forfeit(reason: "Phone was never placed face down within 5 seconds.")
                    return
                }

                HapticsManager.countdownTick()
                self.phase = .armed(secondsLeft: secondsLeft)
            }
        }
    }

    private func beginRunning() {
        var secondsLeft = plannedMinutes * 60
        secondsSinceLastAnchor = 0
        phase = .running(secondsLeft: secondsLeft)

        runTimer?.invalidate()
        runTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { return }

                guard self.motionManager.facing == .faceDown else {
                    timer.invalidate()
                    self.forfeit(reason: "Phone was picked up before the session ended.")
                    return
                }

                secondsLeft -= 1
                self.secondsSinceLastAnchor += 1
                if self.secondsSinceLastAnchor >= self.anchorIntervalSeconds {
                    self.secondsSinceLastAnchor = 0
                    HapticsManager.anchorPulse()
                }

                if secondsLeft <= 0 {
                    timer.invalidate()
                    self.complete()
                    return
                }

                self.phase = .running(secondsLeft: secondsLeft)
            }
        }
    }

    private func forfeit(reason: String) {
        armTimer?.invalidate()
        runTimer?.invalidate()
        motionManager.stopMonitoring()

        activeSession?.outcomeValue = .failure
        activeSession?.failureReason = reason
        activeSession?.endedAt = .now
        try? modelContext?.save()

        HapticsManager.forfeit()
        phase = .forfeited
    }

    private func complete() {
        runTimer?.invalidate()
        motionManager.stopMonitoring()

        activeSession?.outcomeValue = .success
        activeSession?.endedAt = .now
        try? modelContext?.save()

        HapticsManager.success()
        phase = .completed
    }
}

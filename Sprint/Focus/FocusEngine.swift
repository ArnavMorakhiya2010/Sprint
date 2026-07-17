import Foundation
import SwiftData
import SwiftUI
import Combine

enum FocusPhase: Equatable {
    /// Arc dial is live; user is dragging to set the duration (and, for FocusFlight,
    /// picking a departure/arrival).
    case configuring
    /// Pomodoro only. Start was tapped. `secondsLeft` counts down from 5 — the phone
    /// must be leaning, in landscape, before this hits zero or the session forfeits
    /// before it even begins. FocusFlight skips this phase entirely.
    case armed(secondsLeft: Int)
    /// Counting down for real — leaning and monitored (Pomodoro) or in the foreground
    /// (FocusFlight).
    case running(secondsLeft: Int)
    /// Picked up, leveled out, or backgrounded early. Logged as a failure, no break earned.
    case forfeited
    /// Ran the full duration. Rate the session and leave notes before cooldown starts.
    case audit
    /// The mandatory 5-minute lockout after a completed session. Starting is disabled.
    case cooldown(secondsLeft: Int)
}

/// Owns the Focus Engine state machine end to end for both modes:
/// - **Pomodoro**: arc-drag configuring -> 5s armed grace period -> running (CoreMotion
///   leaning check) -> forfeited/audit.
/// - **FocusFlight**: arc-drag configuring -> running (scenePhase foreground check) ->
///   forfeited/audit.
/// A successful run always continues through audit -> a 5-minute cooldown before the
/// engine resets. Every session — success or failure — is written to SwiftData the
/// moment it starts.
@MainActor
final class FocusEngine: ObservableObject {
    @Published private(set) var phase: FocusPhase = .configuring
    @Published private(set) var plannedMinutes: Int = 25
    @Published private(set) var activeMode: SessionMode = .pomodoro
    @Published private(set) var lastFailureReason = ""
    /// Total length of the session currently running, in seconds. FocusFlight's map view
    /// uses this alongside `secondsLeft` to compute how far along the route the plane is.
    @Published private(set) var activeDurationSeconds: Int = 0

    @Published var selectedMode: SessionMode = .pomodoro
    @Published var departure: Destination?
    @Published var arrival: Destination?

    @Published var draftRating: FocusRating?
    @Published var draftNotes: String = ""

    let minMinutes = 5
    let maxMinutes = 120

    private let motionManager = MotionManager()
    private var armTimer: Timer?
    private var runTimer: Timer?
    private var cooldownTimer: Timer?
    private var secondsSinceLastAnchor = 0

    private let armGraceSeconds = 5
    private let anchorIntervalSeconds = 600
    private let cooldownSeconds = 300

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

    var canStart: Bool {
        guard selectedMode == .focusFlight else { return true }
        guard let departure, let arrival else { return false }
        return departure.id != arrival.id
    }

    /// FocusFlight's duration is never set by the user — it's the real great-circle flight
    /// time between the chosen cities.
    var flightDurationMinutes: Int? {
        guard let departure, let arrival else { return nil }
        return FlightCalculator.durationMinutes(from: departure, to: arrival)
    }

    func start() {
        guard case .configuring = phase, canStart, let modelContext else { return }

        let durationMinutes = selectedMode == .focusFlight ? (flightDurationMinutes ?? minMinutes) : plannedMinutes
        let session = FocusSession(mode: selectedMode, plannedDurationSeconds: durationMinutes * 60, subject: activeSubject)
        if selectedMode == .focusFlight {
            session.departureName = departure?.name
            session.arrivalName = arrival?.name
        }
        modelContext.insert(session)
        activeSession = session

        switch selectedMode {
        case .pomodoro:
            motionManager.startMonitoring()
            beginArmingCountdown()
        case .focusFlight:
            beginFlight(totalMinutes: durationMinutes)
        }
    }

    /// Called from the view's `.onChange(of: scenePhase)`. Only FocusFlight sessions care —
    /// leaving the app mid-flight is the crash condition in place of Screen Time blocking.
    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        guard activeMode == .focusFlight, newPhase != .active else { return }
        guard case .running = phase else { return }
        forfeit(reason: "The app was backgrounded mid-flight. The flight crashed.")
    }

    func submitAudit() {
        guard case .audit = phase else { return }
        activeSession?.ratingValue = draftRating
        activeSession?.notes = draftNotes
        try? modelContext?.save()
        draftRating = nil
        draftNotes = ""
        beginCooldown()
    }

    func reset() {
        armTimer?.invalidate()
        runTimer?.invalidate()
        cooldownTimer?.invalidate()
        motionManager.stopMonitoring()
        activeSession = nil
        draftRating = nil
        draftNotes = ""
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

                if self.motionManager.isLeaning {
                    timer.invalidate()
                    self.beginRunning()
                    return
                }

                secondsLeft -= 1
                if secondsLeft <= 0 {
                    timer.invalidate()
                    self.forfeit(reason: "Phone was never propped up leaning within 5 seconds.")
                    return
                }

                HapticsManager.countdownTick()
                self.phase = .armed(secondsLeft: secondsLeft)
            }
        }
    }

    private func beginRunning() {
        activeMode = .pomodoro
        runCountdown(totalMinutes: plannedMinutes) { [weak self] in self?.motionManager.isLeaning ?? false }
    }

    private func beginFlight(totalMinutes: Int) {
        activeMode = .focusFlight
        // Background/inactive transitions are pushed in via handleScenePhaseChange
        // instead of polled here, so the per-second check always passes.
        runCountdown(totalMinutes: totalMinutes) { true }
    }

    private func runCountdown(totalMinutes: Int, shouldContinue: @escaping () -> Bool) {
        var secondsLeft = totalMinutes * 60
        activeDurationSeconds = secondsLeft
        secondsSinceLastAnchor = 0
        phase = .running(secondsLeft: secondsLeft)

        runTimer?.invalidate()
        runTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { return }

                guard shouldContinue() else {
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

    private func beginCooldown() {
        var secondsLeft = cooldownSeconds
        phase = .cooldown(secondsLeft: secondsLeft)

        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { return }
                secondsLeft -= 1
                if secondsLeft <= 0 {
                    timer.invalidate()
                    self.reset()
                    return
                }
                self.phase = .cooldown(secondsLeft: secondsLeft)
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

        lastFailureReason = reason
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
        phase = .audit
    }
}

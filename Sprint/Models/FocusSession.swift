import Foundation
import SwiftData

enum SessionMode: String, Codable, CaseIterable {
    case pomodoro
    case focusFlight

    var displayName: String {
        switch self {
        case .pomodoro: return "Pomodoro"
        case .focusFlight: return "FocusFlight"
        }
    }
}

enum SessionOutcome: String, Codable, CaseIterable {
    case inProgress
    case success
    case failure
    case abandoned
}

enum FocusRating: String, Codable, CaseIterable {
    case good, average, bad
}

/// One Focus Engine attempt — Pomodoro or FocusFlight. Persisted the instant a session
/// starts (not just on success) so failures are logged for analytics.
@Model
final class FocusSession {
    var id: UUID
    /// Backing storage for `modeValue`. Stored as a raw String, not the enum directly,
    /// so the schema is stable across future enum case additions.
    var mode: String
    var plannedDurationSeconds: Int
    var startedAt: Date
    var endedAt: Date?
    var outcome: String
    var failureReason: String?
    var rating: String?
    var notes: String
    /// Only set for `.focusFlight` sessions.
    var departureName: String?
    var arrivalName: String?

    var subject: Subject?

    init(mode: SessionMode, plannedDurationSeconds: Int, subject: Subject? = nil) {
        self.id = UUID()
        self.mode = mode.rawValue
        self.plannedDurationSeconds = plannedDurationSeconds
        self.startedAt = .now
        self.outcome = SessionOutcome.inProgress.rawValue
        self.notes = ""
        self.subject = subject
    }

    var modeValue: SessionMode {
        get { SessionMode(rawValue: mode) ?? .pomodoro }
        set { mode = newValue.rawValue }
    }

    var outcomeValue: SessionOutcome {
        get { SessionOutcome(rawValue: outcome) ?? .inProgress }
        set { outcome = newValue.rawValue }
    }

    var ratingValue: FocusRating? {
        get { rating.flatMap { FocusRating(rawValue: $0) } }
        set { rating = newValue?.rawValue }
    }

    var actualDurationSeconds: Int {
        guard let endedAt else { return 0 }
        return Int(endedAt.timeIntervalSince(startedAt))
    }
}

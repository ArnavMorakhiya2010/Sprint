import Foundation
import SwiftData

/// A single to-do item. Named `StudyTask` (not `Task`) to avoid colliding with Swift's
/// `Task` concurrency type, which every file in this app implicitly has access to.
@Model
final class StudyTask {
    var id: UUID
    var title: String
    var timeEstimateMinutes: Int
    var isFrog: Bool
    var isCompleted: Bool
    var createdAt: Date
    /// Bumped whenever the task is edited or interacted with. Drives Task Decay (Phase 3).
    var lastTouchedAt: Date
    var deadline: Date?
    var completedAt: Date?

    var subject: Subject?

    init(
        title: String,
        timeEstimateMinutes: Int = 30,
        subject: Subject? = nil,
        isFrog: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.timeEstimateMinutes = timeEstimateMinutes
        self.isFrog = isFrog
        self.isCompleted = false
        self.createdAt = .now
        self.lastTouchedAt = .now
        self.subject = subject
    }

    var daysSinceLastTouch: Int {
        Calendar.current.dateComponents([.day], from: lastTouchedAt, to: .now).day ?? 0
    }
}

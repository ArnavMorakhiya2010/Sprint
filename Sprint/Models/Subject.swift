import Foundation
import SwiftData

/// A subject the student is taking (e.g. "Math HL"). Created during onboarding and
/// used as the tag surfaced across the Task Engine, Focus Engine, and Calendar.
@Model
final class Subject {
    var id: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \StudyTask.subject)
    var tasks: [StudyTask] = []

    @Relationship(deleteRule: .nullify, inverse: \FocusSession.subject)
    var sessions: [FocusSession] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
    }
}

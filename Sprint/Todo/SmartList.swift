import SwiftUI

/// Things-3-style smart lists, computed from `StudyTask`'s existing fields rather than a
/// stored status — there's no separate "project/area" concept here, so `subject` doubles
/// as the closest analog: an unassigned task reads as Inbox, an assigned-but-undated one
/// as Anytime.
enum SmartList: String, CaseIterable, Identifiable {
    case inbox, today, upcoming, anytime, someday, logbook

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbox: return "Inbox"
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .anytime: return "Anytime"
        case .someday: return "Someday"
        case .logbook: return "Logbook"
        }
    }

    var systemImage: String {
        switch self {
        case .inbox: return "tray.fill"
        case .today: return "star.fill"
        case .upcoming: return "calendar"
        case .anytime: return "square.stack.fill"
        case .someday: return "archivebox.fill"
        case .logbook: return "checkmark.seal.fill"
        }
    }

    /// Kept inside the app's own palette (orange/peach/espresso) rather than Things'
    /// multicolor icon set, alternating for visual rhythm between list rows.
    var tintColor: Color {
        switch self {
        case .inbox, .today: return Color.theme.orange
        case .upcoming, .logbook: return Color.theme.espresso
        // A deeper peach for a third on-brand tone, without inventing a color outside
        // the app's own palette family.
        case .anytime, .someday: return Color(hex: 0xC97B78)
        }
    }

    func matches(_ task: StudyTask) -> Bool {
        switch self {
        case .inbox:
            return !task.isCompleted && !task.isSomeday && task.subject == nil && task.deadline == nil
        case .today:
            return !task.isCompleted && !task.isSomeday && task.deadline.map { Calendar.current.isDateInToday($0) || $0 < .now } == true
        case .upcoming:
            return !task.isCompleted && !task.isSomeday && task.deadline.map { !Calendar.current.isDateInToday($0) && $0 > .now } == true
        case .anytime:
            return !task.isCompleted && !task.isSomeday && task.subject != nil && task.deadline == nil
        case .someday:
            return !task.isCompleted && task.isSomeday
        case .logbook:
            return task.isCompleted
        }
    }

    func count(in tasks: [StudyTask]) -> Int {
        tasks.filter(matches).count
    }
}

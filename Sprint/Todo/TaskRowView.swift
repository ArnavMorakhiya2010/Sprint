import SwiftUI

/// A single task row, Things-3-style: a checkbox, title, a subject subtitle, and a
/// deadline flag when relevant. Replaces the earlier sticky-note card — clean list rows
/// are what the reference's Things-3 screens actually use.
struct TaskRowView: View {
    let task: StudyTask
    var onToggle: () -> Void
    var onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(task.isCompleted ? Color.theme.orange : Color.theme.espresso.opacity(0.3))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.theme.bodyMedium1())
                    .foregroundStyle(Color.theme.espresso)
                    .strikethrough(task.isCompleted)

                HStack(spacing: 6) {
                    if let subject = task.subject {
                        Text(subject.name)
                            .font(.theme.bodySmall())
                            .foregroundStyle(Color.theme.espresso.opacity(0.5))
                    }
                    if task.isFrog {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.theme.orange.opacity(0.7))
                    }
                    Text("\(task.timeEstimateMinutes)m")
                        .font(.theme.bodySmall())
                        .foregroundStyle(Color.theme.espresso.opacity(0.4))
                }
            }

            Spacer(minLength: 8)

            if let deadline = task.deadline {
                deadlineTag(deadline)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private func deadlineTag(_ date: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(date)
        let isPast = date < .now && !isToday
        return HStack(spacing: 4) {
            Image(systemName: "flag.fill")
                .font(.system(size: 9))
            Text(isToday ? "today" : (isPast ? "overdue" : date.formatted(.dateTime.month(.abbreviated).day())))
                .font(.theme.bodySmall())
        }
        .foregroundStyle(isPast ? Color.theme.orange : Color.theme.espresso.opacity(0.5))
    }
}

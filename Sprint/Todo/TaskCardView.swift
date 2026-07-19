import SwiftUI

/// A task rendered as a slightly rotated sticky note, per the reference To-do List
/// screens — warm pastel fill, soft shadow, torn-paper-style square card rather than a
/// standard list row.
struct TaskCardView: View {
    let task: StudyTask
    let rotation: Double
    let color: Color
    var onToggle: () -> Void
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.theme.espresso)
                }
                Spacer()
                if task.isFrog {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.theme.espresso.opacity(0.55))
                }
            }

            Text(task.title)
                .font(.theme.bodyMedium1())
                .foregroundStyle(Color.theme.espresso)
                .strikethrough(task.isCompleted)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 4)

            HStack {
                if let subject = task.subject {
                    Text(subject.name.uppercased())
                        .font(.theme.bodySmall())
                        .foregroundStyle(Color.theme.espresso.opacity(0.6))
                        .lineLimit(1)
                }
                Spacer()
                Text("\(task.timeEstimateMinutes)m")
                    .font(.theme.bodySmall())
                    .foregroundStyle(Color.theme.espresso.opacity(0.6))
            }
        }
        .padding(14)
        .frame(height: 148)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: Color.theme.espresso.opacity(0.18), radius: 6, y: 4)
        .rotationEffect(.degrees(rotation))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

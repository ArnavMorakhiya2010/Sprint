import SwiftUI
import SwiftData

/// A single smart list's contents — matching the reference's "⭐ Today" style header plus
/// a plain checkbox-row list (recolored to the app's own palette). Inbox additionally gets
/// an inline quick-capture field, Things-3-style, since fast capture is the whole point of
/// an Inbox.
struct SmartListDetailView: View {
    let list: SmartList

    @Environment(\.modelContext) private var modelContext
    @Query private var allTasks: [StudyTask]
    @Query(sort: \Subject.name) private var subjects: [Subject]

    @State private var quickAddText = ""
    @State private var editingTask: StudyTask?
    @State private var showingAddTask = false

    private var tasks: [StudyTask] {
        allTasks
            .filter(list.matches)
            .sorted { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
    }

    var body: some View {
        ZStack {
            Color.theme.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if list == .inbox {
                        quickAddField
                    }

                    if tasks.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 1) {
                            ForEach(tasks) { task in
                                TaskRowView(task: task, onToggle: { toggle(task) }, onTap: { editingTask = task })
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.theme.espresso.opacity(0.06), radius: 8, y: 4)
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle(list.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.theme.orange)
                }
            }
        }
        .sheet(item: $editingTask) { task in
            AddTaskView(subjects: subjects, editing: task)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(subjects: subjects, presetList: list)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: list.systemImage)
                .font(.system(size: 20))
                .foregroundStyle(list.tintColor)
            Text(list.title)
                .font(.theme.h1Large())
                .foregroundStyle(Color.theme.espresso)
        }
        .padding(.top, 4)
    }

    private var quickAddField: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.theme.orange)
            TextField("New to-do", text: $quickAddText)
                .font(.theme.bodyLarge())
                .foregroundStyle(Color.theme.espresso)
                .submitLabel(.done)
                .onSubmit(quickAdd)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Capsule().fill(Color.white))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            PomMascotView(pose: .idle, size: 64)
            Text("Nothing here")
                .font(.theme.h3())
                .foregroundStyle(Color.theme.espresso)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }

    private func quickAdd() {
        let trimmed = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let task = StudyTask(title: trimmed)
        modelContext.insert(task)
        try? modelContext.save()
        quickAddText = ""
    }

    private func toggle(_ task: StudyTask) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? .now : nil
        task.lastTouchedAt = .now
        try? modelContext.save()
    }
}

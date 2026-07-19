import SwiftUI
import SwiftData

/// The To-do List tab: a search bar, an add button, and tasks rendered as a grid of
/// rotated sticky notes in cycling warm pastel tones, per the reference.
struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyTask.createdAt, order: .reverse) private var tasks: [StudyTask]
    @Query(sort: \Subject.name) private var subjects: [Subject]

    @State private var searchText = ""
    @State private var showingAddTask = false
    @State private var editingTask: StudyTask?

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    private let rotations: [Double] = [-3, 2.5, -2, 3, -2.5, 2]
    private let cardColors: [Color] = [Color.theme.orange.opacity(0.55), Color.theme.peach, Color.white]

    private var filteredTasks: [StudyTask] {
        guard !searchText.isEmpty else { return tasks }
        return tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.theme.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("To-do List")
                        .font(.theme.h1Large())
                        .foregroundStyle(Color.theme.espresso)
                        .padding(.top, 8)

                    searchBar

                    if filteredTasks.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(Array(filteredTasks.enumerated()), id: \.element.id) { index, task in
                                TaskCardView(
                                    task: task,
                                    rotation: rotations[index % rotations.count],
                                    color: cardColors[index % cardColors.count],
                                    onToggle: { toggleComplete(task) },
                                    onTap: { editingTask = task }
                                )
                            }
                        }
                    }
                }
                .padding(24)
                .padding(.bottom, 110)
            }

            addButton
                .padding(.trailing, 28)
                .padding(.bottom, 100)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(subjects: subjects)
        }
        .sheet(item: $editingTask) { task in
            AddTaskView(subjects: subjects, editing: task)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.theme.espresso.opacity(0.5))
            TextField("Search tasks", text: $searchText)
                .font(.theme.bodyLarge())
                .foregroundStyle(Color.theme.espresso)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Capsule().fill(Color.white))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            PomMascotView(pose: .idle, size: 72)
            Text(searchText.isEmpty ? "No tasks yet" : "No matches")
                .font(.theme.h2())
                .foregroundStyle(Color.theme.espresso)
            Text("Tap + to add your first task.")
                .font(.theme.bodyMedium2())
                .foregroundStyle(Color.theme.espresso.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var addButton: some View {
        Button(action: { showingAddTask = true }) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.theme.cream)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.theme.orange))
                .shadow(color: Color.theme.espresso.opacity(0.25), radius: 10, y: 6)
        }
    }

    private func toggleComplete(_ task: StudyTask) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? .now : nil
        task.lastTouchedAt = .now
        try? modelContext.save()
    }
}

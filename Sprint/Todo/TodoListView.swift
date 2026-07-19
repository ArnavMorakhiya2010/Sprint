import SwiftUI
import SwiftData

/// The To-do tab's root: a Things-3-style sidebar of smart lists (Inbox, Today, Upcoming,
/// Anytime, Someday, Logbook), each showing a live count, recolored to the app's own
/// palette. Tapping a row pushes `SmartListDetailView`.
struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [StudyTask]
    @Query(sort: \Subject.name) private var subjects: [Subject]

    @State private var searchText = ""
    @State private var showingQuickAdd = false
    @State private var editingTask: StudyTask?

    private var searchResults: [StudyTask] {
        guard !searchText.isEmpty else { return [] }
        return tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.theme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        searchBar

                        if !searchText.isEmpty {
                            searchResultsSection
                        } else {
                            smartListsSection
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }

                addButton
                    .padding(.trailing, 28)
                    .padding(.bottom, 100)
            }
            .navigationTitle("To-do")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingQuickAdd) {
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
            TextField("Quick Find", text: $searchText)
                .font(.theme.bodyLarge())
                .foregroundStyle(Color.theme.espresso)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.theme.espresso.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Capsule().fill(Color.white))
    }

    private var smartListsSection: some View {
        VStack(spacing: 1) {
            ForEach(SmartList.allCases) { list in
                NavigationLink {
                    SmartListDetailView(list: list)
                } label: {
                    smartListRow(list)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.theme.espresso.opacity(0.06), radius: 8, y: 4)
    }

    private func smartListRow(_ list: SmartList) -> some View {
        HStack(spacing: 14) {
            Image(systemName: list.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.theme.cream)
                .frame(width: 30, height: 30)
                .background(Circle().fill(list.tintColor))

            Text(list.title)
                .font(.theme.bodyMedium1())
                .foregroundStyle(Color.theme.espresso)

            Spacer()

            let count = list.count(in: tasks)
            if count > 0 {
                Text("\(count)")
                    .font(.theme.bodySmall())
                    .foregroundStyle(Color.theme.espresso.opacity(0.4))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.theme.espresso.opacity(0.25))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if searchResults.isEmpty {
                Text("No matches")
                    .font(.theme.bodyMedium2())
                    .foregroundStyle(Color.theme.espresso.opacity(0.5))
                    .padding(.top, 20)
            } else {
                VStack(spacing: 1) {
                    ForEach(searchResults) { task in
                        TaskRowView(task: task, onToggle: { toggleComplete(task) }, onTap: { editingTask = task })
                    }
                }
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }

    private var addButton: some View {
        Button(action: { showingQuickAdd = true }) {
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

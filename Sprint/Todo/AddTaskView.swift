import SwiftUI
import SwiftData

/// Add/edit sheet for a `StudyTask`. Passing `editing` switches this into edit mode
/// (pre-filled fields, a delete option); omitting it creates a new task on save.
struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let subjects: [Subject]
    var editing: StudyTask?

    @State private var title: String
    @State private var selectedSubject: Subject?
    @State private var minutes: Double
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var shakeTitle = false

    init(subjects: [Subject], editing: StudyTask? = nil) {
        self.subjects = subjects
        self.editing = editing
        _title = State(initialValue: editing?.title ?? "")
        _selectedSubject = State(initialValue: editing?.subject)
        _minutes = State(initialValue: Double(editing?.timeEstimateMinutes ?? 30))
        _hasDeadline = State(initialValue: editing?.deadline != nil)
        _deadline = State(initialValue: editing?.deadline ?? .now)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        titleField
                        subjectField
                        durationField
                        deadlineField
                        saveButton
                        if editing != nil {
                            deleteButton
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(editing == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.theme.bodySmall())
            .foregroundStyle(Color.theme.espresso.opacity(0.5))
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("TASK")
            TextField("e.g. Past paper — Section A", text: $title)
                .font(.theme.bodyLarge())
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Capsule().fill(Color.white))
                .foregroundStyle(Color.theme.espresso)
                .offset(x: shakeTitle ? 10 : 0)
        }
    }

    private var subjectField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("SUBJECT")
            Menu {
                Button("General") { selectedSubject = nil }
                ForEach(subjects) { subject in
                    Button(subject.name) { selectedSubject = subject }
                }
            } label: {
                HStack {
                    Text(selectedSubject?.name ?? "General")
                        .font(.theme.bodyLarge())
                        .foregroundStyle(Color.theme.espresso)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.theme.espresso.opacity(0.5))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Capsule().fill(Color.white))
            }
        }
    }

    private var durationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("DURATION")
            HStack {
                stepperButton(system: "minus") { minutes = max(5, minutes - 5) }
                Text("\(Int(minutes)) min")
                    .font(.theme.bodyLarge())
                    .foregroundStyle(Color.theme.espresso)
                    .frame(maxWidth: .infinity)
                stepperButton(system: "plus") { minutes = min(240, minutes + 5) }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white))
        }
    }

    private func stepperButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.theme.cream)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.theme.orange))
        }
    }

    private var deadlineField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                fieldLabel("DEADLINE")
                Spacer()
                Toggle("", isOn: $hasDeadline.animation())
                    .labelsHidden()
                    .tint(Color.theme.orange)
            }
            if hasDeadline {
                DatePicker("", selection: $deadline, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.graphical)
                    .tint(Color.theme.orange)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
            }
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("SAVE")
                .font(.theme.button())
                .foregroundStyle(Color.theme.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.theme.orange))
        }
        .padding(.top, 8)
    }

    private var deleteButton: some View {
        Button(action: delete) {
            Text("DELETE TASK")
                .font(.theme.button())
                .foregroundStyle(Color.theme.espresso)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().stroke(Color.theme.peach, lineWidth: 1.5))
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            withAnimation(.easeInOut(duration: 0.15)) { shakeTitle = true }
            withAnimation(.easeInOut(duration: 0.15).delay(0.15)) { shakeTitle = false }
            return
        }

        if let editing {
            editing.title = trimmed
            editing.subject = selectedSubject
            editing.timeEstimateMinutes = Int(minutes)
            editing.deadline = hasDeadline ? deadline : nil
            editing.lastTouchedAt = .now
        } else {
            let task = StudyTask(title: trimmed, timeEstimateMinutes: Int(minutes), subject: selectedSubject)
            task.deadline = hasDeadline ? deadline : nil
            modelContext.insert(task)
        }
        try? modelContext.save()
        dismiss()
    }

    private func delete() {
        guard let editing else { return }
        modelContext.delete(editing)
        try? modelContext.save()
        dismiss()
    }
}

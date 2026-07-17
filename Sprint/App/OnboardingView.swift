import SwiftUI
import SwiftData

/// First-run setup. Collects the four inputs the rest of the app is built around — name,
/// age, active subjects, and the Sleep Lockout Time (bedtime) that will later cap how much
/// can be scheduled in a day. `RootView` keeps this on screen until `hasCompletedOnboarding`
/// flips true, so there's no way into the main app without providing them.
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userAge") private var userAge: Int = 0
    @AppStorage("bedtimeHour") private var bedtimeHour: Int = 22
    @AppStorage("bedtimeMinute") private var bedtimeMinute: Int = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var step = 0
    @State private var nameInput = ""
    @State private var ageInput = ""
    @State private var subjectInput = ""
    @State private var subjectNames: [String] = []
    @State private var bedtime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now) ?? .now
    @State private var shakeName = false
    @State private var shakeAge = false
    @State private var shakeSubject = false

    private let totalSteps = 4

    var body: some View {
        ZStack {
            Color.theme.cream.ignoresSafeArea()

            VStack(spacing: 24) {
                progressDots

                PomMascotView(pose: .idle, size: 72)

                Spacer()

                Group {
                    switch step {
                    case 0: nameStep
                    case 1: ageStep
                    case 2: subjectsStep
                    default: bedtimeStep
                    }
                }
                .id(step)
                .transition(.opacity.combined(with: .move(edge: .trailing)))

                Spacer()

                continueButton
            }
            .padding(24)
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index == step ? Color.theme.orange : Color.theme.peach)
                    .frame(width: index == step ? 24 : 8, height: 8)
            }
        }
        .padding(.top, 24)
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What should we call you?")
                .font(.theme.h1Small())
                .foregroundStyle(Color.theme.espresso)

            TextField("Your name", text: $nameInput)
                .font(.theme.bodyLarge())
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.white))
                .overlay(Capsule().stroke(Color.theme.peach, lineWidth: 1.5))
                .foregroundStyle(Color.theme.espresso)
                .offset(x: shakeName ? 10 : 0)
        }
    }

    private var ageStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How old are you?")
                .font(.theme.h1Small())
                .foregroundStyle(Color.theme.espresso)

            TextField("Age", text: $ageInput)
                .keyboardType(.numberPad)
                .font(.theme.bodyLarge())
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.white))
                .overlay(Capsule().stroke(Color.theme.peach, lineWidth: 1.5))
                .foregroundStyle(Color.theme.espresso)
                .offset(x: shakeAge ? 10 : 0)
        }
    }

    private var subjectsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What are you studying?")
                .font(.theme.h1Small())
                .foregroundStyle(Color.theme.espresso)

            Text("Add each subject — these become tags across the app, and what you'll pick from when you start a Pomodoro.")
                .font(.theme.bodyMedium2())
                .foregroundStyle(Color.theme.espresso.opacity(0.6))

            HStack(spacing: 10) {
                TextField("e.g. Math HL", text: $subjectInput)
                    .font(.theme.bodyLarge())
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.white))
                    .overlay(Capsule().stroke(Color.theme.peach, lineWidth: 1.5))
                    .foregroundStyle(Color.theme.espresso)
                    .submitLabel(.done)
                    .onSubmit(addSubject)
                    .offset(x: shakeSubject ? 10 : 0)

                Button(action: addSubject) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.theme.cream)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(Color.theme.orange))
                }
            }

            if !subjectNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(subjectNames, id: \.self) { name in
                            subjectChip(name)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func subjectChip(_ name: String) -> some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.theme.bodyMedium2())
                .foregroundStyle(Color.theme.espresso)
            Button {
                subjectNames.removeAll { $0 == name }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.theme.espresso.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.theme.peach.opacity(0.5)))
    }

    private var bedtimeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("When's lights out?")
                .font(.theme.h1Small())
                .foregroundStyle(Color.theme.espresso)

            Text("Your Sleep Lockout Time sets how many hours you have to work with each day.")
                .font(.theme.bodyMedium2())
                .foregroundStyle(Color.theme.espresso.opacity(0.65))

            DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.wheel)
                .tint(Color.theme.orange)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        }
    }

    private var continueButton: some View {
        Button(action: advance) {
            Text(step == totalSteps - 1 ? "GET STARTED" : "CONTINUE")
                .font(.theme.button())
                .foregroundStyle(Color.theme.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.theme.orange))
        }
    }

    private func addSubject() {
        let trimmed = subjectInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !subjectNames.contains(trimmed) else {
            shake($shakeSubject)
            return
        }
        subjectNames.append(trimmed)
        subjectInput = ""
    }

    private func advance() {
        switch step {
        case 0:
            let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                shake($shakeName)
                return
            }
            userName = trimmed
            step = 1
        case 1:
            guard let age = Int(ageInput), (5...100).contains(age) else {
                shake($shakeAge)
                return
            }
            userAge = age
            step = 2
        case 2:
            guard !subjectNames.isEmpty else {
                shake($shakeSubject)
                return
            }
            step = 3
        default:
            let components = Calendar.current.dateComponents([.hour, .minute], from: bedtime)
            bedtimeHour = components.hour ?? 22
            bedtimeMinute = components.minute ?? 0
            for name in subjectNames {
                modelContext.insert(Subject(name: name))
            }
            try? modelContext.save()
            hasCompletedOnboarding = true
        }
    }

    private func shake(_ flag: Binding<Bool>) {
        withAnimation(.easeInOut(duration: 0.15)) { flag.wrappedValue = true }
        withAnimation(.easeInOut(duration: 0.15).delay(0.15)) { flag.wrappedValue = false }
    }
}

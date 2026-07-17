import SwiftUI

/// First-run setup. Collects the three inputs the rest of the app is built around — name,
/// age, and the Sleep Lockout Time (bedtime) that will later cap how much can be scheduled
/// in a day. `RootView` keeps this on screen until `hasCompletedOnboarding` flips true, so
/// there's no way into the main app without providing them.
struct OnboardingView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userAge") private var userAge: Int = 0
    @AppStorage("bedtimeHour") private var bedtimeHour: Int = 22
    @AppStorage("bedtimeMinute") private var bedtimeMinute: Int = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var step = 0
    @State private var nameInput = ""
    @State private var ageInput = ""
    @State private var bedtime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now) ?? .now
    @State private var shakeName = false
    @State private var shakeAge = false

    private let totalSteps = 3

    var body: some View {
        ZStack {
            Color.theme.pearl.ignoresSafeArea()

            VStack(spacing: 32) {
                progressDots

                Spacer()

                Group {
                    switch step {
                    case 0: nameStep
                    case 1: ageStep
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
                    .fill(index == step ? Color.theme.taupe : Color.theme.khaki)
                    .frame(width: index == step ? 24 : 8, height: 8)
            }
        }
        .padding(.top, 24)
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What should we call you?")
                .font(.theme.header(26))
                .foregroundStyle(Color.theme.leather)

            TextField("Your name", text: $nameInput)
                .font(.theme.body(18))
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.theme.khaki))
                .foregroundStyle(Color.theme.leather)
                .offset(x: shakeName ? 10 : 0)
        }
    }

    private var ageStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How old are you?")
                .font(.theme.header(26))
                .foregroundStyle(Color.theme.leather)

            TextField("Age", text: $ageInput)
                .keyboardType(.numberPad)
                .font(.theme.body(18))
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.theme.khaki))
                .foregroundStyle(Color.theme.leather)
                .offset(x: shakeAge ? 10 : 0)
        }
    }

    private var bedtimeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("When's lights out?")
                .font(.theme.header(26))
                .foregroundStyle(Color.theme.leather)

            Text("Your Sleep Lockout Time sets how many hours you have to work with each day.")
                .font(.theme.body(15))
                .foregroundStyle(Color.theme.leather.opacity(0.65))

            DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.wheel)
                .tint(Color.theme.taupe)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.theme.khaki))
        }
    }

    private var continueButton: some View {
        Button(action: advance) {
            Text(step == totalSteps - 1 ? "GET STARTED" : "CONTINUE")
                .font(.theme.header(16))
                .foregroundStyle(Color.theme.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.theme.leather))
        }
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
        default:
            let components = Calendar.current.dateComponents([.hour, .minute], from: bedtime)
            bedtimeHour = components.hour ?? 22
            bedtimeMinute = components.minute ?? 0
            hasCompletedOnboarding = true
        }
    }

    private func shake(_ flag: Binding<Bool>) {
        withAnimation(.easeInOut(duration: 0.15)) { flag.wrappedValue = true }
        withAnimation(.easeInOut(duration: 0.15).delay(0.15)) { flag.wrappedValue = false }
    }
}

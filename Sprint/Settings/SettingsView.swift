import SwiftUI

/// The Settings tab. Rows that are actually functional (Profile, Sleep Lockout Time,
/// default Soundscape, Reset) behave like normal controls. Rows the sitemap calls for but
/// that need a real backend this app doesn't have (Google auth, password change, account
/// deactivation) are shown visibly disabled with a "Soon" badge rather than pretending to
/// work — nothing here is a dead end dressed up as a feature.
struct SettingsView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("userAge") private var userAge = 0
    @AppStorage("bedtimeHour") private var bedtimeHour = 22
    @AppStorage("bedtimeMinute") private var bedtimeMinute = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("defaultSoundscape") private var defaultSoundscapeRaw = Soundscape.off.rawValue

    @State private var showingProfileEdit = false
    @State private var showingAbout = false
    @State private var showingPrivacy = false
    @State private var showingResetConfirm = false

    private var defaultSoundscape: Soundscape {
        Soundscape(rawValue: defaultSoundscapeRaw) ?? .off
    }

    var body: some View {
        ZStack {
            Color.theme.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Settings")
                        .font(.theme.h1Large())
                        .foregroundStyle(Color.theme.espresso)
                        .padding(.top, 8)

                    profileSection
                    preferencesSection
                    accountSection
                    aboutSection
                    logoutRow
                }
                .padding(24)
                .padding(.bottom, 90)
            }
        }
        .sheet(isPresented: $showingProfileEdit) { ProfileEditSheet() }
        .sheet(isPresented: $showingAbout) {
            InfoSheet(
                title: "About Sprint",
                message: "Sprint is a focus timer built to fight procrastination with strict mechanics: a leaning/landscape check that ends a session the moment you pick your phone up, real flight-time FocusFlight sessions, and a to-do list, reports, and settings to go with it."
            )
        }
        .sheet(isPresented: $showingPrivacy) {
            InfoSheet(
                title: "Privacy Policy",
                message: "Sprint stores everything — your profile, subjects, tasks, and session history — locally on this device via SwiftData. Nothing is sent to a server, because this build doesn't have one."
            )
        }
        .confirmationDialog(
            "Reset onboarding? You'll be asked for your name, age, subjects, and bedtime again.",
            isPresented: $showingResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) { hasCompletedOnboarding = false }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        sectionCard(title: "PROFILE") {
            row(title: userName.isEmpty ? "My Profile" : userName, subtitle: "Age \(userAge) · Lights out \(bedtimeLabel)", systemImage: "person.fill") {
                showingProfileEdit = true
            }
        }
    }

    private var preferencesSection: some View {
        sectionCard(title: "PREFERENCES") {
            Menu {
                ForEach(Soundscape.allCases) { option in
                    Button(option.label) { defaultSoundscapeRaw = option.rawValue }
                }
            } label: {
                row(title: "Default Sound", subtitle: defaultSoundscape.label, systemImage: "speaker.wave.2.fill", showChevron: true)
            }
            Divider().padding(.leading, 52)
            row(title: "Sleep Lockout Time", subtitle: bedtimeLabel, systemImage: "moon.fill") {
                showingProfileEdit = true
            }
        }
    }

    private var accountSection: some View {
        sectionCard(title: "ACCOUNT") {
            inertRow(title: "Google Sign-In", systemImage: "person.badge.key.fill")
            Divider().padding(.leading, 52)
            inertRow(title: "Change Password", systemImage: "lock.fill")
            Divider().padding(.leading, 52)
            inertRow(title: "Deactivate Account", systemImage: "person.crop.circle.badge.minus")
        }
    }

    private var aboutSection: some View {
        sectionCard(title: "ABOUT") {
            row(title: "About Sprint", systemImage: "info.circle.fill") { showingAbout = true }
            Divider().padding(.leading, 52)
            row(title: "Privacy Policy", systemImage: "hand.raised.fill") { showingPrivacy = true }
        }
    }

    private var logoutRow: some View {
        Button(action: { showingResetConfirm = true }) {
            Text("RESET ONBOARDING")
                .font(.theme.button())
                .foregroundStyle(Color.theme.espresso)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().stroke(Color.theme.peach, lineWidth: 1.5))
        }
    }

    private var bedtimeLabel: String {
        String(format: "%02d:%02d", bedtimeHour, bedtimeMinute)
    }

    // MARK: - Row builders

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.theme.bodySmall())
                .foregroundStyle(Color.theme.espresso.opacity(0.5))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
            .shadow(color: Color.theme.espresso.opacity(0.06), radius: 8, y: 4)
        }
    }

    private func row(title: String, subtitle: String? = nil, systemImage: String, showChevron: Bool = true, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.theme.orange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.theme.bodyMedium1())
                        .foregroundStyle(Color.theme.espresso)
                    if let subtitle {
                        Text(subtitle)
                            .font(.theme.bodySmall())
                            .foregroundStyle(Color.theme.espresso.opacity(0.5))
                    }
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.theme.espresso.opacity(0.3))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .disabled(action == nil)
    }

    private func inertRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 15))
                .foregroundStyle(Color.theme.espresso.opacity(0.3))
                .frame(width: 24)

            Text(title)
                .font(.theme.bodyMedium1())
                .foregroundStyle(Color.theme.espresso.opacity(0.4))

            Spacer()

            Text("SOON")
                .font(.theme.bodySmall())
                .foregroundStyle(Color.theme.espresso.opacity(0.4))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.theme.peach.opacity(0.5)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

/// A simple static-content sheet, reused for About and Privacy Policy.
private struct InfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let message: String

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.cream.ignoresSafeArea()
                ScrollView {
                    Text(message)
                        .font(.theme.bodyLarge())
                        .foregroundStyle(Color.theme.espresso)
                        .padding(24)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct ProfileEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var userName = ""
    @AppStorage("userAge") private var userAge = 0
    @AppStorage("bedtimeHour") private var bedtimeHour = 22
    @AppStorage("bedtimeMinute") private var bedtimeMinute = 0

    @State private var nameInput = ""
    @State private var ageInput = ""
    @State private var bedtime = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.cream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        fieldLabel("NAME")
                        TextField("Your name", text: $nameInput)
                            .font(.theme.bodyLarge())
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.white))
                            .foregroundStyle(Color.theme.espresso)

                        fieldLabel("AGE")
                        TextField("Age", text: $ageInput)
                            .keyboardType(.numberPad)
                            .font(.theme.bodyLarge())
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.white))
                            .foregroundStyle(Color.theme.espresso)

                        fieldLabel("SLEEP LOCKOUT TIME")
                        DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.wheel)
                            .tint(Color.theme.orange)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))

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
                    .padding(24)
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                nameInput = userName
                ageInput = "\(userAge)"
                bedtime = Calendar.current.date(bySettingHour: bedtimeHour, minute: bedtimeMinute, second: 0, of: .now) ?? .now
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.theme.bodySmall())
            .foregroundStyle(Color.theme.espresso.opacity(0.5))
    }

    private func save() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { userName = trimmed }
        if let age = Int(ageInput), (5...100).contains(age) { userAge = age }
        let components = Calendar.current.dateComponents([.hour, .minute], from: bedtime)
        bedtimeHour = components.hour ?? bedtimeHour
        bedtimeMinute = components.minute ?? bedtimeMinute
        dismiss()
    }
}

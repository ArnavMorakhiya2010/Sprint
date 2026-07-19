import SwiftUI

enum AppTab: CaseIterable {
    case home, todo, reports, settings

    var label: String {
        switch self {
        case .home: return "Home"
        case .todo: return "To-do"
        case .reports: return "Reports"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .todo: return "checklist"
        case .reports: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

/// The app's root shell: a floating, fully-rounded pill tab bar over four screens, per the
/// sitemap (Onboarding → Home/Focus, To-do Lists, Reports, Settings).
struct MainTabView: View {
    @AppStorage("defaultSoundscape") private var defaultSoundscapeRaw = Soundscape.off.rawValue
    @State private var selectedTab: AppTab = .home
    @StateObject private var soundscape = SoundscapePlayer()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.theme.cream.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home: HomeTabView()
                case .todo: TodoListView()
                case .reports: ReportsView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
        .environmentObject(soundscape)
        .onAppear {
            // Settings' "Default Sound" picker only sets a preference; this is what
            // actually makes it take effect for a freshly launched session.
            soundscape.current = Soundscape(rawValue: defaultSoundscapeRaw) ?? .off
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.theme.espresso))
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 17, weight: .semibold))
                Text(tab.label)
                    .font(.theme.bodySmall())
            }
            .foregroundStyle(isSelected ? Color.theme.orange : Color.theme.cream.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }
}

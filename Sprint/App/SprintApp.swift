import SwiftUI
import SwiftData

@main
struct SprintApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Subject.self, StudyTask.self, FocusSession.self])
    }
}

import SwiftUI
import SwiftData

@main
struct SprintApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Subject.self, StudyTask.self, FocusSession.self])
    }
}

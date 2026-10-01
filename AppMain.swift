import SwiftUI
import SwiftData

@main
struct TrackHobbiesApp: App {
    init() {
        Analytics.setup()
        SyncMonitor.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataStore.shared.modelContainer)
    }
}

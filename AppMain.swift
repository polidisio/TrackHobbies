import SwiftUI
import SwiftData

@main
struct TrackHobbiesApp: App {
    init() {
        #if DEBUG
        DemoSeed.runIfRequested()
        #endif
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

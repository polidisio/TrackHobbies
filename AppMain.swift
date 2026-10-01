import SwiftUI
import SwiftData

@main
struct TrackHobbiesApp: App {
    init() { Analytics.setup() }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataStore.shared.modelContainer)
    }
}

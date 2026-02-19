import SwiftUI
import SwiftData

@main
struct TrackHobbiesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataStore.shared.modelContainer)
    }
}

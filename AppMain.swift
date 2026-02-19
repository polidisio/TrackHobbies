import SwiftUI
import SwiftData

@main
struct TrackHobbiesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ResourceEntity.self)
    }
}

import Foundation
import SwiftData

@MainActor
final class DataStore {
    static let shared = DataStore()
    
    let modelContainer: ModelContainer
    
    private init() {
        let schema = Schema([ResourceEntity.self, PendingItemEntity.self])
        
        let url = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TrackHobbies.sqlite")
        
        let config = ModelConfiguration(
            schema: schema,
            url: url,
            cloudKitDatabase: .none
        )
        
        do {
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
            print("DataStore: persistent storage at \(url.path)")
        } catch {
            fatalError("DataStore: could not create ModelContainer – \(error)")
        }
    }
}

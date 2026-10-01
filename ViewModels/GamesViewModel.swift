import Foundation
import SwiftUI
import SwiftData

@MainActor
final class GamesViewModel: ObservableObject, Searchable {
    @Published var searchResults: [GameItem] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var errorMessage: String?
    
    func searchGames() async {
        await performSearch { try await GameSearchService.shared.searchGames(title: $0) }
    }
    
    func addGame(from item: GameItem, context: ModelContext) {
        let game = ResourceEntity(
            type: .game,
            title: item.title,
            externalId: item.id,
            imageURL: item.imageURL,
            status: .notStarted
        )
        
        context.insert(game)
        Analytics.track("resource_added", ["type": "game", "source": "search"])
        
        do {
            try context.save()
            searchResults = []
            searchQuery = ""
        } catch {
            print("Error saving game: \(error)")
        }
    }

    func addGameToWishlist(from item: GameItem, context: ModelContext) {
        let game = ResourceEntity(
            type: .game,
            title: item.title,
            externalId: item.id,
            imageURL: item.imageURL,
            status: .wishlist
        )
        
        context.insert(game)
        Analytics.track("resource_added", ["type": "game", "source": "wishlist"])
        
        do {
            try context.save()
            searchResults = []
            searchQuery = ""
        } catch {
            print("Error saving game: \(error)")
        }
    }
    
    func addGame(title: String, context: ModelContext) {
        let game = ResourceEntity(
            type: .game,
            title: title,
            status: .notStarted
        )
        
        context.insert(game)
        Analytics.track("resource_added", ["type": "game", "source": "manual"])
        
        do {
            try context.save()
        } catch {
            print("Error saving game: \(error)")
        }
    }
}

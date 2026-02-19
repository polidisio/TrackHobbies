import Foundation
import SwiftUI
import SwiftData

@MainActor
final class GamesViewModel: ObservableObject {
    @Published var searchResults: [RAWGGameItem] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var apiKey: String = ""
    
    func searchGames() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        let service = RAWGService(apiKey: apiKey.isEmpty ? nil : apiKey)
        service.searchGames(title: searchQuery) { [weak self] results in
            Task { @MainActor in
                self?.searchResults = results
                self?.isLoading = false
            }
        }
    }
    
    func addGame(from item: RAWGGameItem, context: ModelContext) {
        let game = ResourceEntity(
            type: .game,
            title: item.title,
            externalId: item.id,
            imageURL: item.imageURL,
            status: .notStarted
        )
        
        context.insert(game)
        
        do {
            try context.save()
            searchResults = []
            searchQuery = ""
        } catch {
            print("Error saving game: \(error)")
        }
    }

    func addGameToWishlist(from item: RAWGGameItem, context: ModelContext) {
        let game = ResourceEntity(
            type: .game,
            title: item.title,
            externalId: item.id,
            imageURL: item.imageURL,
            status: .wishlist
        )
        
        context.insert(game)
        
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
        
        do {
            try context.save()
        } catch {
            print("Error saving game: \(error)")
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}

import Foundation
import SwiftUI
import SwiftData

@MainActor
final class GamesViewModel: ObservableObject {
    @Published var games: [ResourceEntity] = []
    @Published var searchResults: [RAWGGameItem] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var apiKey: String = ""
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchGames()
    }
    
    func fetchGames() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<ResourceEntity>(
            predicate: #Predicate { $0.type == "game" },
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        
        do {
            games = try context.fetch(descriptor)
        } catch {
            print("Error fetching games: \(error)")
        }
    }
    
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
            fetchGames()
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
            fetchGames()
        } catch {
            print("Error saving game: \(error)")
        }
    }
    
    func updateGame(_ game: ResourceEntity) {
        game.lastUpdated = Date()
        
        do {
            try modelContext?.save()
            fetchGames()
        } catch {
            print("Error updating game: \(error)")
        }
    }
    
    func deleteGame(_ game: ResourceEntity) {
        modelContext?.delete(game)
        
        do {
            try modelContext?.save()
            fetchGames()
        } catch {
            print("Error deleting game: \(error)")
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}

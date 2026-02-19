import Foundation
import SwiftUI
import SwiftData

@MainActor
final class SeriesViewModel: ObservableObject {
    @Published var searchResults: [TVMazeSearchResult] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    
    func searchSeries() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        TVMazeService.shared.searchShows(title: searchQuery) { [weak self] results in
            Task { @MainActor in
                self?.searchResults = results
                self?.isLoading = false
            }
        }
    }
    
    func addSeries(from result: TVMazeSearchResult, context: ModelContext) {
        let serie = ResourceEntity(
            type: .series,
            title: result.title,
            imageURL: result.imageURL,
            summary: result.summary,
            status: .notStarted
        )
        
        context.insert(serie)

        TVMazeService.shared.fetchSeasons(showId: result.id) { totalSeasons, totalEpisodes in
            if totalSeasons > 0 {
                serie.totalSeasons = totalSeasons
            }
            if totalEpisodes > 0 {
                serie.totalEpisodes = totalEpisodes
            }
        }
        
        do {
            try context.save()
            searchResults = []
            searchQuery = ""
        } catch {
            print("Error saving series: \(error)")
        }
    }
    
    func addSeries(title: String, summary: String? = nil, context: ModelContext) {
        let serie = ResourceEntity(
            type: .series,
            title: title,
            summary: summary,
            status: .notStarted
        )
        
        context.insert(serie)
        
        do {
            try context.save()
        } catch {
            print("Error saving series: \(error)")
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}

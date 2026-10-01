import Foundation
import SwiftUI
import SwiftData

@MainActor
final class SeriesViewModel: ObservableObject, Searchable {
    @Published var searchResults: [TVMazeSearchResult] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var errorMessage: String?
    
    func searchSeries() async {
        await performSearch { try await TVMazeService.shared.searchShows(title: $0) }
    }

    func addSeries(from result: TVMazeSearchResult, context: ModelContext) {
        insert(result, status: .notStarted, context: context)
    }

    func addSeriesToWishlist(from result: TVMazeSearchResult, context: ModelContext) {
        insert(result, status: .wishlist, context: context)
    }

    private func insert(_ result: TVMazeSearchResult, status: ProgressStatus, context: ModelContext) {
        let serie = ResourceEntity(
            type: .series,
            title: result.title,
            imageURL: result.imageURL,
            summary: result.summary,
            status: status
        )
        context.insert(serie)
        do {
            try context.save()
            searchResults = []
            searchQuery = ""
        } catch {
            print("Error saving series: \(error)")
        }

        // Totales de temporadas/episodios: llegan después; best-effort, se guardan al llegar.
        Task {
            guard let totals = try? await TVMazeService.shared.fetchSeasons(showId: result.id) else { return }
            if totals.seasons > 0 { serie.totalSeasons = totals.seasons }
            if totals.episodes > 0 { serie.totalEpisodes = totals.episodes }
            try? context.save()
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
}

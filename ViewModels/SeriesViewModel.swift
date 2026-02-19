import Foundation
import SwiftUI
import SwiftData

@MainActor
final class SeriesViewModel: ObservableObject {
    @Published var series: [ResourceEntity] = []
    @Published var searchResults: [TVMazeSearchResult] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchSeries()
    }
    
    func fetchSeries() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<ResourceEntity>(
            predicate: #Predicate { $0.type == "series" },
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        
        do {
            series = try context.fetch(descriptor)
        } catch {
            print("Error fetching series: \(error)")
        }
    }
    
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
        
        do {
            try context.save()
            fetchSeries()
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
            fetchSeries()
        } catch {
            print("Error saving series: \(error)")
        }
    }
    
    func updateSeries(_ serie: ResourceEntity) {
        serie.lastUpdated = Date()
        
        do {
            try modelContext?.save()
            fetchSeries()
        } catch {
            print("Error updating series: \(error)")
        }
    }
    
    func deleteSeries(_ serie: ResourceEntity) {
        modelContext?.delete(serie)
        
        do {
            try modelContext?.save()
            fetchSeries()
        } catch {
            print("Error deleting series: \(error)")
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}

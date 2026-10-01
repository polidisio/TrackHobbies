import Foundation

/// Estado + lógica de búsqueda compartida por Books/Series/Games.
/// Pensado para llamarse desde `.task(id: viewModel.searchQuery)`: SwiftUI cancela la
/// búsqueda anterior al cambiar el texto, así que el debounce es el `sleep` inicial.
@MainActor
protocol Searchable: AnyObject {
    associatedtype Item
    var searchQuery: String { get set }
    var searchResults: [Item] { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
}

extension Searchable {
    func performSearch(_ fetch: (String) async throws -> [Item]) async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        guard !query.isEmpty else {
            searchResults = []
            isLoading = false
            return
        }
        isLoading = true
        do {
            try await Task.sleep(for: .milliseconds(400))
            searchResults = try await fetch(query)
        } catch is CancellationError {
            return // reemplazada por una búsqueda nueva: ella gestiona isLoading
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            searchResults = []
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        errorMessage = nil
        isLoading = false
    }
}

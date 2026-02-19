import Foundation
import SwiftUI
import SwiftData

@MainActor
final class BooksViewModel: ObservableObject {
    @Published var searchResults: [GoogleBookItem] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    
    func searchBooks() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        GoogleBooksService.shared.search(title: searchQuery) { [weak self] results in
            Task { @MainActor in
                self?.searchResults = results
                self?.isLoading = false
            }
        }
    }
    
    func addBook(from item: GoogleBookItem, context: ModelContext) {
        let book = ResourceEntity(
            type: .book,
            title: item.title,
            externalId: item.externalId,
            imageURL: item.coverURL,
            summary: item.summary,
            authorOrCreator: item.author,
            status: .notStarted,
            totalPages: item.numberOfPages
        )
        context.insert(book)
        searchResults = []
        searchQuery = ""
    }
    
    func addBook(title: String, author: String?, context: ModelContext) {
        let book = ResourceEntity(
            type: .book,
            title: title,
            authorOrCreator: author,
            status: .notStarted
        )
        context.insert(book)
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}

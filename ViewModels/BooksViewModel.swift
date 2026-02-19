import Foundation
import SwiftUI
import SwiftData

@MainActor
final class BooksViewModel: ObservableObject {
    @Published var searchResults: [OpenLibraryItem] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    
    func searchBooks() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        OpenLibraryService.shared.search(title: searchQuery) { [weak self] results in
            Task { @MainActor in
                self?.searchResults = results
                self?.isLoading = false
            }
        }
    }
    
    func addBook(from item: OpenLibraryItem, context: ModelContext) {
        let book = ResourceEntity(
            type: .book,
            title: item.title,
            externalId: item.externalId,
            imageURL: item.coverURL,
            authorOrCreator: item.author,
            status: .notStarted,
            totalPages: item.numberOfPages
        )
        context.insert(book)
        searchResults = []
        searchQuery = ""

        if let workKey = item.externalId {
            Task {
                let description = await withCheckedContinuation { continuation in
                    OpenLibraryService.shared.fetchWorkDescription(workKey: workKey) { desc in
                        continuation.resume(returning: desc)
                    }
                }
                if let description = description {
                    book.summary = description
                    try? context.save()
                }
            }
        }
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

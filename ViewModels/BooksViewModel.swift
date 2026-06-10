import Foundation
import SwiftUI
import SwiftData

@MainActor
final class BooksViewModel: ObservableObject {
    @Published var searchResults: [GoogleBookItem] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var importProgress: Double = 0
    @Published var isImporting = false
    
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

    func addBookToWishlist(from item: GoogleBookItem, context: ModelContext) {
        let book = ResourceEntity(
            type: .book,
            title: item.title,
            externalId: item.externalId,
            imageURL: item.coverURL,
            summary: item.summary,
            authorOrCreator: item.author,
            status: .wishlist,
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

    func importBooks(_ books: [GoodreadsCSVBook], context: ModelContext, enrichWithGoogleBooks: Bool = false) {
        isImporting = true
        importProgress = 0

        let group = DispatchGroup()
        var enrichedCount = 0

        for (index, book) in books.enumerated() {
            group.enter()

            var entity = GoodreadsImporter.mapToResourceEntity(book)

            if enrichWithGoogleBooks, let isbn = book.isbn13 ?? book.isbn {
                GoogleBooksService.shared.searchByISBN(isbn) { googleBook in
                    if let gb = googleBook {
                        entity.imageURL = gb.coverURL
                        if entity.summary == nil || entity.summary?.isEmpty == true {
                            entity.summary = gb.summary
                        }
                        if entity.totalPages == nil {
                            entity.totalPages = gb.numberOfPages
                        }
                        if entity.authorOrCreator == nil || entity.authorOrCreator?.isEmpty == true {
                            entity.authorOrCreator = gb.author
                        }
                        enrichedCount += 1
                    }
                    DispatchQueue.main.async {
                        context.insert(entity)
                        self.importProgress = Double(index + 1) / Double(books.count)
                        group.leave()
                    }
                }
            } else {
                context.insert(entity)
                DispatchQueue.main.async {
                    self.importProgress = Double(index + 1) / Double(books.count)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            self.isImporting = false
            self.importProgress = 0
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}

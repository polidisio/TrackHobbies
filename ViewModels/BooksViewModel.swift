import Foundation
import SwiftUI
import SwiftData

@MainActor
final class BooksViewModel: ObservableObject, Searchable {
    @Published var searchResults: [GoogleBookItem] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var errorMessage: String?
    @Published var importProgress: Double = 0
    @Published var isImporting = false
    
    func searchBooks() async {
        await performSearch { try await GoogleBooksService.shared.search(title: $0) }
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

        // Secuencial a propósito: 1 petición a la vez no revienta la cuota de Google Books
        // y mantiene las mutaciones de los @Model en el hilo principal.
        // ponytail: lento con miles de libros; subir a concurrencia limitada (TaskGroup de 4) si molesta.
        Task {
            var enrich = enrichWithGoogleBooks
            for (index, book) in books.enumerated() {
                let entity = GoodreadsImporter.mapToResourceEntity(book)
                if enrich, let isbn = book.isbn13 ?? book.isbn {
                    do {
                        if let gb = try await GoogleBooksService.shared.searchByISBN(isbn) {
                            entity.imageURL = gb.coverURL
                            if entity.summary?.isEmpty ?? true { entity.summary = gb.summary }
                            if entity.totalPages == nil { entity.totalPages = gb.numberOfPages }
                            if entity.authorOrCreator?.isEmpty ?? true { entity.authorOrCreator = gb.author }
                        }
                    } catch SearchError.rateLimited {
                        enrich = false // dejamos de enriquecer, pero importamos el resto
                    } catch {}
                }
                context.insert(entity)
                importProgress = Double(index + 1) / Double(books.count)
            }
            do { try context.save() } catch { print("Error saving imported books: \(error)") }
            isImporting = false
            importProgress = 0
        }
    }
}

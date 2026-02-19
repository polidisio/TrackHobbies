import Foundation
import SwiftUI
import SwiftData

@MainActor
final class BooksViewModel: ObservableObject {
    @Published var books: [ResourceEntity] = []
    @Published var searchResults: [OpenLibraryItem] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchBooks()
    }
    
    func fetchBooks() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<ResourceEntity>(
            predicate: #Predicate { $0.type == "book" },
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        
        do {
            books = try context.fetch(descriptor)
        } catch {
            print("Error fetching books: \(error)")
        }
    }
    
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
            status: .notStarted
        )
        
        context.insert(book)
        
        do {
            try context.save()
            fetchBooks()
            searchResults = []
            searchQuery = ""
        } catch {
            print("Error saving book: \(error)")
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
        
        do {
            try context.save()
            fetchBooks()
        } catch {
            print("Error saving book: \(error)")
        }
    }
    
    func updateBook(_ book: ResourceEntity) {
        book.lastUpdated = Date()
        
        do {
            try modelContext?.save()
            fetchBooks()
        } catch {
            print("Error updating book: \(error)")
        }
    }
    
    func deleteBook(_ book: ResourceEntity) {
        modelContext?.delete(book)
        
        do {
            try modelContext?.save()
            fetchBooks()
        } catch {
            print("Error deleting book: \(error)")
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}

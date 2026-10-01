import Foundation

struct GoogleBookItem: Decodable {
    let title: String
    let author: String
    let coverURL: String?
    let externalId: String
    let numberOfPages: Int?
    let summary: String?
}

private struct BookSearchResponse: Decodable {
    let results: [GoogleBookItem]
}

/// Búsqueda de libros vía el Worker de Cloudflare (`worker/`), que guarda la clave de Google Books.
final class GoogleBooksService {
    static let shared = GoogleBooksService()
    private init() {}

    func search(title: String) async throws -> [GoogleBookItem] {
        try await URLSession.shared.worker(BookSearchResponse.self, path: "/books/search", query: ["q": title]).results
    }

    func searchByISBN(_ isbn: String) async throws -> GoogleBookItem? {
        try await URLSession.shared.worker(BookSearchResponse.self, path: "/books/isbn", query: ["isbn": isbn]).results.first
    }
}

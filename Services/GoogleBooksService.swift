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
        func fetch() async throws -> [GoogleBookItem] {
            try await URLSession.shared.worker(BookSearchResponse.self, path: "/books/search", query: ["q": title]).results
        }
        // Google Books da 502/503 sueltos (el Worker no reintenta): un segundo intento lo suele resolver.
        do { return try await fetch() } catch SearchError.server {
            try await Task.sleep(for: .milliseconds(600))
            return try await fetch()
        }
    }

    /// Ediciones de un libro por título y autor (los `isbn:` de Google devuelven 0 resultados).
    func searchEditions(title: String, author: String?) async throws -> [GoogleBookItem] {
        try await search(title: BookMatch.query(title: title, author: author))
    }

    func searchByISBN(_ isbn: String) async throws -> GoogleBookItem? {
        try await URLSession.shared.worker(BookSearchResponse.self, path: "/books/isbn", query: ["isbn": isbn]).results.first
    }
}

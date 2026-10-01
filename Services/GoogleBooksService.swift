import Foundation

struct GoogleBooksVolume: Decodable {
    let id: String
    let volumeInfo: GoogleBooksVolumeInfo
}

struct GoogleBooksVolumeInfo: Decodable {
    let title: String?
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let imageLinks: GoogleBooksImageLinks?
}

struct GoogleBooksImageLinks: Decodable {
    let thumbnail: String?
}

struct GoogleBooksResponse: Decodable {
    let items: [GoogleBooksVolume]?
}

struct GoogleBookItem {
    let title: String
    let author: String
    let coverURL: String?
    let externalId: String
    let numberOfPages: Int?
    let summary: String?
}

final class GoogleBooksService {
    static let shared = GoogleBooksService()
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"

    private init() {}

    func search(title: String) async throws -> [GoogleBookItem] {
        try await fetch(query: title, maxResults: 20).map(Self.item)
    }

    func searchByISBN(_ isbn: String) async throws -> GoogleBookItem? {
        try await fetch(query: "isbn:\(isbn)", maxResults: 1).first.map(Self.item)
    }

    private func fetch(query: String, maxResults: Int) async throws -> [GoogleBooksVolume] {
        guard var components = URLComponents(string: baseURL) else { throw SearchError.badResponse }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: String(maxResults))
        ]
        // Sin clave propia se usa la cuota anónima compartida, casi siempre agotada (429).
        if let key = Bundle.main.object(forInfoDictionaryKey: "GoogleBooksAPIKey") as? String, !key.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "key", value: key))
        }
        guard let url = components.url else { throw SearchError.badResponse }
        return try await URLSession.shared.decode(GoogleBooksResponse.self, from: url).items ?? []
    }

    private static func item(_ vol: GoogleBooksVolume) -> GoogleBookItem {
        GoogleBookItem(
            title: vol.volumeInfo.title ?? "",
            author: vol.volumeInfo.authors?.joined(separator: ", ") ?? "",
            coverURL: vol.volumeInfo.imageLinks?.thumbnail?.replacingOccurrences(of: "http://", with: "https://"),
            externalId: vol.id,
            numberOfPages: vol.volumeInfo.pageCount,
            summary: vol.volumeInfo.description
        )
    }
}

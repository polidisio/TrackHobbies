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

    func search(title: String, completion: @escaping ([GoogleBookItem]) -> Void) {
        guard var components = URLComponents(string: baseURL) else {
            completion([]); return
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: title),
            URLQueryItem(name: "maxResults", value: "20")
        ]
        guard let url = components.url else { completion([]); return }

        URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, _ in
            var results: [GoogleBookItem] = []
            if let data = data {
                if let decoded = try? JSONDecoder().decode(GoogleBooksResponse.self, from: data) {
                    if let items = decoded.items {
                        results = items.map { vol in
                            let author = vol.volumeInfo.authors?.joined(separator: ", ") ?? ""
                            let thumbnail = vol.volumeInfo.imageLinks?.thumbnail?
                                .replacingOccurrences(of: "http://", with: "https://")
                            return GoogleBookItem(
                                title: vol.volumeInfo.title ?? "",
                                author: author,
                                coverURL: thumbnail,
                                externalId: vol.id,
                                numberOfPages: vol.volumeInfo.pageCount,
                                summary: vol.volumeInfo.description
                            )
                        }
                    }
                }
            }
            DispatchQueue.main.async { completion(results) }
        }.resume()
    }
}

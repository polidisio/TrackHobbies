import Foundation

struct OpenLibraryDoc: Decodable {
    let title: String?
    let author_name: [String]?
    let cover_i: Int?
    let key: String?
}

struct OpenLibraryResponse: Decodable {
    let docs: [OpenLibraryDoc]?
}

struct OpenLibraryItem {
    let title: String
    let author: String
    let coverURL: String?
    let externalId: String?
}

final class OpenLibraryService {
    static let shared = OpenLibraryService()
    private let baseURL = "https://openlibrary.org/search.json"

    func search(title: String, completion: @escaping ([OpenLibraryItem]) -> Void) {
        guard var components = URLComponents(string: baseURL) else {
            completion([]); return
        }
        components.queryItems = [URLQueryItem(name: "title", value: title)]
        guard let url = components.url else { completion([]); return }

        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, _ in
            var results: [OpenLibraryItem] = []
            if let data = data {
                if let decoded = try? JSONDecoder().decode(OpenLibraryResponse.self, from: data) {
                    if let docs = decoded.docs {
                        results = docs.map { d in
                            let author = d.author_name?.first ?? ""
                            let coverURL: String? = {
                                if let ci = d.cover_i {
                                    return "https://covers.openlibrary.org/b/id/\(ci)-M.jpg"
                                } else {
                                    return nil
                                }
                            }()
                            let externalId = d.key?.replacingOccurrences(of: "/works/", with: "")
                            return OpenLibraryItem(title: d.title ?? "", author: author, coverURL: coverURL, externalId: externalId)
                        }
                    }
                }
            }
            DispatchQueue.main.async { completion(results) }
        }
        task.resume()
    }
}

import Foundation

struct OpenLibraryDoc: Decodable {
    let title: String?
    let author_name: [String]?
    let cover_i: Int?
    let key: String?
    let number_of_pages_median: Int?
    let description: String?
}

struct OpenLibraryResponse: Decodable {
    let docs: [OpenLibraryDoc]?
}

struct OpenLibraryWorkResponse: Decodable {
    let description: DescriptionValue?

    enum DescriptionValue: Decodable {
        case string(String)
        case object(ObjectDescription)

        struct ObjectDescription: Decodable {
            let value: String?
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                self = .string(str)
            } else if let obj = try? container.decode(ObjectDescription.self) {
                self = .object(obj)
            } else {
                self = .string("")
            }
        }

        var text: String {
            switch self {
            case .string(let s): return s
            case .object(let o): return o.value ?? ""
            }
        }
    }
}

struct OpenLibraryItem {
    let title: String
    let author: String
    let coverURL: String?
    let externalId: String?
    let numberOfPages: Int?
    let summary: String?
}

final class OpenLibraryService {
    static let shared = OpenLibraryService()
    private let baseURL = "https://openlibrary.org/search.json"

    func search(title: String, completion: @escaping ([OpenLibraryItem]) -> Void) {
        guard var components = URLComponents(string: baseURL) else {
            completion([]); return
        }
        components.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "fields", value: "key,title,author_name,cover_i,number_of_pages_median,description"),
            URLQueryItem(name: "limit", value: "20")
        ]
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
                            return OpenLibraryItem(
                                title: d.title ?? "",
                                author: author,
                                coverURL: coverURL,
                                externalId: externalId,
                                numberOfPages: d.number_of_pages_median,
                                summary: d.description
                            )
                        }
                    }
                }
            }
            DispatchQueue.main.async { completion(results) }
        }
        task.resume()
    }

    func fetchWorkDescription(workKey: String, completion: @escaping (String?) -> Void) {
        let urlStr = "https://openlibrary.org/works/\(workKey).json"
        guard let url = URL(string: urlStr) else { completion(nil); return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            var description: String?
            if let data = data {
                if let decoded = try? JSONDecoder().decode(OpenLibraryWorkResponse.self, from: data) {
                    let text = decoded.description?.text ?? ""
                    if !text.isEmpty {
                        description = text
                    }
                }
            }
            DispatchQueue.main.async { completion(description) }
        }.resume()
    }
}

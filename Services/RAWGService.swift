import Foundation

struct RAWGGame: Decodable {
    let id: Int
    let name: String
    let background_image: String?
    let released: String?
    let genres: [RAWGGenre]?
}

struct RAWGGenre: Decodable {
    let name: String
}

struct RAWGResponse: Decodable {
    let results: [RAWGGame]
}

struct RAWGGameItem {
    let id: String
    let title: String
    let imageURL: String?
    let released: String?
    let genres: [String]?
}

final class RAWGService {
    static let shared = RAWGService()
    private let baseURL = "https://api.rawg.io/api/games"
    var apiKey: String?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey
    }

    func searchGames(title: String, completion: @escaping ([RAWGGameItem]) -> Void) {
        var components = URLComponents(string: baseURL)
        var key = apiKey
        if key == nil { key = "" }
        components?.queryItems = [URLQueryItem(name: "search", value: title), URLQueryItem(name: "key", value: key)]
        guard let url = components?.url else { completion([]); return }
        URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, _ in
            var results: [RAWGGameItem] = []
            if let data = data {
                if let decoded = try? JSONDecoder().decode(RAWGResponse.self, from: data) {
                    results = decoded.results.map { g in
                        let genres = g.genres?.map { $0.name }
                        return RAWGGameItem(id: String(g.id), title: g.name, imageURL: g.background_image, released: g.released, genres: genres)
                    }
                }
            }
            DispatchQueue.main.async { completion(results) }
        }.resume()
    }
}

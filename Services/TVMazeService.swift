import Foundation

struct TVMazeShow: Decodable {
    let id: Int
    let name: String
    let summary: String?
    let image: TVMazeImage?
}

struct TVMazeImage: Decodable {
    let medium: String?
    let original: String?
}

struct TVMazeSeason: Decodable {
    let id: Int
    let number: Int?
    let episodeOrder: Int?
}

struct TVMazeSearchResult {
    let id: Int
    let title: String
    let imageURL: String?
    let summary: String?
}

final class TVMazeService {
    static let shared = TVMazeService()
    private init() {}

    func searchShows(title: String) async throws -> [TVMazeSearchResult] {
        var components = URLComponents(string: "https://api.tvmaze.com/search/shows")
        components?.queryItems = [URLQueryItem(name: "q", value: title)]
        guard let url = components?.url else { throw SearchError.badResponse }
        return try await URLSession.shared.decode([TVMazeShowContainer].self, from: url).map {
            TVMazeSearchResult(id: $0.show.id, title: $0.show.name, imageURL: $0.show.image?.medium, summary: $0.show.summary)
        }
    }

    func fetchSeasons(showId: Int) async throws -> (seasons: Int, episodes: Int) {
        guard let url = URL(string: "https://api.tvmaze.com/shows/\(showId)/seasons") else { throw SearchError.badResponse }
        let seasons = try await URLSession.shared.decode([TVMazeSeason].self, from: url)
        return (seasons.count, seasons.compactMap(\.episodeOrder).reduce(0, +))
    }
}

struct TVMazeShowContainer: Decodable {
    let show: TVMazeShow
}

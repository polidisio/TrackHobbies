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
    private let baseURL = "https://api.tvmaze.com/search/shows?q="

    func searchShows(title: String, completion: @escaping ([TVMazeSearchResult]) -> Void) {
        guard let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion([]); return
        }
        let urlStr = baseURL + encoded
        guard let url = URL(string: urlStr) else { completion([]); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            var results: [TVMazeSearchResult] = []
            if let data = data {
                if let decoded = try? JSONDecoder().decode([TVMazeShowContainer].self, from: data) {
                    results = decoded.map { c in
                        let s = c.show
                        let img = s.image?.medium
                        return TVMazeSearchResult(id: s.id, title: s.name, imageURL: img, summary: s.summary)
                    }
                }
            }
            DispatchQueue.main.async { completion(results) }
        }.resume()
    }

    func fetchSeasons(showId: Int, completion: @escaping (Int, Int) -> Void) {
        let urlStr = "https://api.tvmaze.com/shows/\(showId)/seasons"
        guard let url = URL(string: urlStr) else { completion(0, 0); return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            var totalSeasons = 0
            var totalEpisodes = 0
            if let data = data {
                if let seasons = try? JSONDecoder().decode([TVMazeSeason].self, from: data) {
                    totalSeasons = seasons.count
                    totalEpisodes = seasons.compactMap { $0.episodeOrder }.reduce(0, +)
                }
            }
            DispatchQueue.main.async { completion(totalSeasons, totalEpisodes) }
        }.resume()
    }
}

struct TVMazeShowContainer: Decodable {
    let show: TVMazeShow
}

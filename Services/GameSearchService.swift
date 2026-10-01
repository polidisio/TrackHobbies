import Foundation

struct GameItem: Decodable {
    let id: String
    let title: String
    let imageURL: String?
    let released: String?
    let genres: [String]?
}

private struct GameSearchResponse: Decodable {
    let results: [GameItem]
}

/// Búsqueda de juegos vía el Worker de Cloudflare (`worker/`), que guarda las claves de IGDB.
final class GameSearchService {
    static let shared = GameSearchService()
    private init() {}

    func searchGames(title: String) async throws -> [GameItem] {
        try await URLSession.shared.worker(GameSearchResponse.self, path: "/games/search", query: ["q": title]).results
    }
}

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
        guard let host = Bundle.main.object(forInfoDictionaryKey: "GameAPIHost") as? String, !host.isEmpty,
              let token = Bundle.main.object(forInfoDictionaryKey: "GameAPIToken") as? String, !token.isEmpty
        else { throw SearchError.notConfigured }

        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/games/search"
        components.queryItems = [URLQueryItem(name: "q", value: title)]
        guard let url = components.url else { throw SearchError.badResponse }
        return try await URLSession.shared.decode(GameSearchResponse.self, from: url, headers: ["X-App-Token": token]).results
    }
}

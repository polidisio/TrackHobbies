import Foundation

enum SearchError: LocalizedError {
    case offline, rateLimited, unauthorized, notConfigured, server, badResponse

    var errorDescription: String? {
        switch self {
        case .offline: return String(localized: "Sin conexión o conexión muy lenta. Revisa tu red e inténtalo de nuevo.")
        case .rateLimited: return String(localized: "Demasiadas búsquedas seguidas. Espera un momento e inténtalo de nuevo.")
        case .unauthorized: return String(localized: "El servicio rechazó la petición (clave de la app no válida).")
        case .notConfigured: return String(localized: "La búsqueda no está configurada en esta compilación.")
        case .server: return String(localized: "El servicio no responde ahora mismo. Inténtalo más tarde.")
        case .badResponse: return String(localized: "Respuesta inesperada del servicio.")
        }
    }
}

extension URLSession {
    /// GET + decode. Cancelación (`CancellationError` / `URLError.cancelled`) se propaga tal cual.
    func decode<T: Decodable>(_ type: T.Type, from url: URL, headers: [String: String] = [:]) async throws -> T {
        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await self.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .timedOut:
                throw SearchError.offline
            default:
                throw error
            }
        }
        if let status = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(status) {
            switch status {
            case 429: throw SearchError.rateLimited
            case 401, 403: throw SearchError.unauthorized
            case 500...: throw SearchError.server
            default: throw SearchError.badResponse
            }
        }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw SearchError.badResponse
        }
    }
}

extension URLSession {
    /// GET al Worker de Cloudflare (`worker/`), que guarda las claves de IGDB y Google Books.
    func worker<T: Decodable>(_ type: T.Type, path: String, query: [String: String]) async throws -> T {
        guard let host = Bundle.main.object(forInfoDictionaryKey: "GameAPIHost") as? String, !host.isEmpty,
              let token = Bundle.main.object(forInfoDictionaryKey: "GameAPIToken") as? String, !token.isEmpty
        else { throw SearchError.notConfigured }

        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else { throw SearchError.badResponse }
        return try await decode(type, from: url, headers: ["X-App-Token": token])
    }
}

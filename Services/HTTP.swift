import Foundation

enum SearchError: LocalizedError {
    case offline, rateLimited, unauthorized, notConfigured, server, badResponse

    var errorDescription: String? {
        switch self {
        case .offline: return String(localized: "Sin conexión o conexión muy lenta. Revisa tu red e inténtalo de nuevo.")
        case .rateLimited: return String(localized: "Demasiadas búsquedas seguidas. Espera un momento e inténtalo de nuevo.")
        case .unauthorized: return String(localized: "El servicio rechazó la petición (clave de la app no válida).")
        case .notConfigured: return String(localized: "La búsqueda de juegos no está configurada en esta compilación.")
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

import Foundation

enum ResourceType: String, Codable, CaseIterable {
    case book
    case series
    case game
    
    var displayName: String {
        switch self {
        case .book: return "Libro"
        case .series: return "Serie"
        case .game: return "Juego"
        }
    }
    
    var icon: String {
        switch self {
        case .book: return "book"
        case .series: return "tv"
        case .game: return "gamecontroller"
        }
    }
}

enum ProgressStatus: String, Codable, CaseIterable {
    case wishlist = "wishlist"
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case archived = "archived"
    
    var displayName: String {
        switch self {
        case .wishlist: return "Pendiente"
        case .notStarted: return "Sin empezar"
        case .inProgress: return "En progreso"
        case .completed: return "Completado"
        case .archived: return "Archivado"
        }
    }
}

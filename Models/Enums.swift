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
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .notStarted: return "Sin empezar"
        case .inProgress: return "En progreso"
        case .completed: return "Completado"
        }
    }
}

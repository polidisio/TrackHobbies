import Foundation
import SwiftUI

enum ResourceType: String, Codable, CaseIterable {
    case book
    case series
    case game

    var displayName: String {
        switch self {
        case .book: return String(localized: "Libro")
        case .series: return String(localized: "Serie")
        case .game: return String(localized: "Juego")
        }
    }

    var icon: String {
        switch self {
        case .book: return "book"
        case .series: return "tv"
        case .game: return "gamecontroller"
        }
    }

    var filledIcon: String {
        switch self {
        case .book: return "book.fill"
        case .series: return "tv.fill"
        case .game: return "gamecontroller.fill"
        }
    }

    var color: Color {
        switch self {
        case .book: return AppTheme.bookColor
        case .series: return AppTheme.seriesColor
        case .game: return AppTheme.gameColor
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
        case .wishlist: return String(localized: "Pendiente")
        case .notStarted: return String(localized: "Sin empezar")
        case .inProgress: return String(localized: "En progreso")
        case .completed: return String(localized: "Completado")
        case .archived: return String(localized: "Archivado")
        }
    }

    var sectionTitle: String {
        switch self {
        case .wishlist: return String(localized: "Pendientes")
        case .notStarted: return String(localized: "Sin empezar")
        case .inProgress: return String(localized: "En progreso")
        case .completed: return String(localized: "Completados")
        case .archived: return String(localized: "Archivados")
        }
    }

    var icon: String {
        switch self {
        case .wishlist: return "bookmark.fill"
        case .notStarted: return "circle"
        case .inProgress: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .archived: return "archivebox.fill"
        }
    }

    var color: Color {
        switch self {
        case .wishlist: return .orange
        case .notStarted: return .gray
        case .inProgress: return AppTheme.accent
        case .completed: return .green
        case .archived: return Color(.systemGray3)
        }
    }
}

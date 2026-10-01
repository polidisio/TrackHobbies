import Foundation

/// Reglas del seguimiento por páginas. Puras para poder probarlas sin UI.
enum PageTracking {
    static let maxPages = 10_000

    enum TotalError: Error, Equatable {
        case invalid
        case belowCurrent(Int)
    }

    /// Valida el texto del editor del total: entero 1…`maxPages` y nunca menor que la página actual.
    static func validateTotal(_ raw: String, currentPage: Int?) -> Result<Int, TotalError> {
        guard let total = Int(raw.trimmingCharacters(in: .whitespaces)), (1...maxPages).contains(total) else {
            return .failure(.invalid)
        }
        if let current = currentPage, current > total { return .failure(.belowCurrent(current)) }
        return .success(total)
    }

    /// Sin total no hay tope; con total la página actual no pasa del final.
    static func clampedPage(_ page: Int, total: Int?) -> Int {
        let page = max(page, 0)
        guard let total, total > 0 else { return page }
        return min(page, total)
    }

    static func isFinished(page: Int?, total: Int?) -> Bool {
        guard let page, let total, total > 0 else { return false }
        return page >= total
    }
}

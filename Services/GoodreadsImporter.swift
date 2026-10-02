import Foundation
import SwiftData
import SwiftUI

struct GoodreadsCSVBook: Identifiable {
    let id = UUID()
    let title: String
    let author: String?
    let isbn: String?
    let isbn13: String?
    let myRating: Double?
    let numberOfPages: Int?
    let dateRead: Date?
    let exclusiveShelf: String
    let bookshelves: String?
    let review: String?
}

struct GoodreadsImporter {
    private static let dateFormats = ["yyyy/MM/dd", "yyyy-MM-dd"]

    private static func date(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        for format in dateFormats {
            f.dateFormat = format
            if let d = f.date(from: s) { return d }
        }
        return nil
    }

    /// Clave para no duplicar libros al reimportar: título (sin la serie de Goodreads) + autor, normalizados.
    static func dedupeKey(title: String, author: String?) -> String {
        BookMatch.normalize(BookMatch.cleanTitle(title)) + "|" + BookMatch.normalize(author ?? "")
    }

    /// CSV de «Mis libros» de Goodreads. Usa el parser RFC 4180 (las reseñas pueden llevar saltos de línea y comillas).
    static func parse(csvContent: String) -> [GoodreadsCSVBook] {
        let rows = CSVImporter.parseRows(csvContent)
        guard let header = rows.first else { return [] }
        let junk = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\u{FEFF}"))
        let col = Dictionary(header.enumerated().map { ($1.trimmingCharacters(in: junk).lowercased(), $0) },
                             uniquingKeysWith: { a, _ in a })

        return rows.dropFirst().compactMap { row in
            func get(_ key: String) -> String? {
                guard let i = col[key], i < row.count else { return nil }
                let v = row[i].trimmingCharacters(in: .whitespaces)
                return v.isEmpty ? nil : v
            }
            guard let title = get("title") else { return nil }
            return GoodreadsCSVBook(
                title: title,
                author: get("author"),
                isbn: get("isbn").flatMap(cleanISBN),
                isbn13: get("isbn13").flatMap(cleanISBN),
                // Goodreads usa 0 para «sin puntuar»
                myRating: get("my rating").flatMap(Double.init).flatMap { $0 > 0 ? $0 : nil },
                numberOfPages: get("number of pages").flatMap(Int.init).flatMap { $0 > 0 ? $0 : nil },
                dateRead: get("date read").flatMap(date),
                exclusiveShelf: get("exclusive shelf") ?? "to-read",
                bookshelves: get("bookshelves"),
                review: get("my review").map(cleanReview).flatMap { $0.isEmpty ? nil : $0 }
            )
        }
    }

    /// Goodreads guarda los saltos de línea de la reseña como `<br/>`.
    private static func cleanReview(_ s: String) -> String {
        s.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `="0441172717"` → `0441172717`; `=""` → nil.
    private static func cleanISBN(_ value: String) -> String? {
        let cleaned = value.filter { $0 != "=" && $0 != "\"" }.trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? nil : cleaned
    }

    static func mapToResourceEntity(_ book: GoodreadsCSVBook) -> ResourceEntity {
        ResourceEntity(
            type: .book,
            title: BookMatch.stripSeries(book.title),
            externalId: book.isbn13 ?? book.isbn,
            authorOrCreator: book.author,
            userRating: book.myRating,
            status: mapShelfToStatus(book.exclusiveShelf),
            lastUpdated: Date(),
            totalPages: book.numberOfPages,
            endDate: book.dateRead,
            reviewComment: book.review
        )
    }

    private static func mapShelfToStatus(_ shelf: String) -> ProgressStatus {
        switch shelf.lowercased() {
        case "read": return .completed
        case "currently-reading": return .inProgress
        case "to-read": return .wishlist
        default: return .notStarted
        }
    }
}

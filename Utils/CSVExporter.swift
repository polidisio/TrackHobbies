import Foundation
import SwiftData

struct CSVBook {
    let title: String
    let author: String?
    let isbn: String?
    let rating: Double?
    let status: String
    let pages: Int?
    let dateRead: Date?
    let review: String?
}

struct CSVExporter {
    static func export(books: [CSVBook]) -> String {
        var lines: [String] = []
        lines.append("title,author,isbn,rating,status,pages,date_read,review")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"

        for book in books {
            let titleField = book.title.replacingOccurrences(of: "\"", with: "\"\"")
            let author = (book.author ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let isbn = (book.isbn ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let review = (book.review ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let dateRead = book.dateRead.map { dateFormatter.string(from: $0) } ?? ""

            let line = "\"\(titleField)\",\"\(author)\",\"\(isbn)\",\"\(book.rating ?? 0)\",\"\(book.status)\",\"\(book.pages ?? 0)\",\"\(dateRead)\",\"\(review)\""
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    static func exportFromEntities(_ entities: [ResourceEntity]) -> String {
        let books = entities.map { entity in
            CSVBook(
                title: entity.title,
                author: entity.authorOrCreator,
                isbn: entity.externalId,
                rating: entity.userRating,
                status: entity.progressStatus.displayName,
                pages: entity.totalPages,
                dateRead: entity.endDate,
                review: entity.reviewComment
            )
        }
        return export(books: books)
    }
}

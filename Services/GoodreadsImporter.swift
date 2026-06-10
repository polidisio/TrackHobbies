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
}

struct GoodreadsImporter {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    static func parse(csvContent: String) -> [GoodreadsCSVBook] {
        let lines = csvContent.components(separatedBy: .newlines)
        guard lines.count > 1 else { return [] }

        let headerLine = lines[0].lowercased()
        let headers = parseCSVLine(headerLine)

        var books: [GoodreadsCSVBook] = []

        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            let values = parseCSVLine(line)

            guard let titleIndex = headers.firstIndex(of: "title"),
                  titleIndex < values.count,
                  !values[titleIndex].isEmpty else { continue }

            let title = cleanGoodreadsValue(values[titleIndex])

            let author = getValue(for: "author", headers: headers, values: values).flatMap { cleanGoodreadsValue($0) }
            let isbn = getValue(for: "isbn", headers: headers, values: values).flatMap { cleanISBN($0) }
            let isbn13 = getValue(for: "isbn13", headers: headers, values: values).flatMap { cleanISBN($0) }
            let ratingString = getValue(for: "my rating", headers: headers, values: values)
            let myRating = ratingString.flatMap { Double($0) }
            let pagesString = getValue(for: "number of pages", headers: headers, values: values)
            let numberOfPages = pagesString.flatMap { Int($0) }
            let dateReadString = getValue(for: "date read", headers: headers, values: values)
            let dateRead = dateReadString.flatMap { dateFormatter.date(from: $0) }
            let exclusiveShelf = getValue(for: "exclusive shelf", headers: headers, values: values) ?? "to-read"
            let bookshelves = getValue(for: "bookshelves", headers: headers, values: values)

            let book = GoodreadsCSVBook(
                title: title,
                author: author,
                isbn: isbn,
                isbn13: isbn13,
                myRating: myRating,
                numberOfPages: numberOfPages,
                dateRead: dateRead,
                exclusiveShelf: exclusiveShelf,
                bookshelves: bookshelves
            )
            books.append(book)
        }

        return books
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)

        return result
    }

    private static func cleanGoodreadsValue(_ value: String) -> String {
        var cleaned = value
        if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
            cleaned = String(cleaned.dropFirst().dropLast())
        }
        cleaned = cleaned.replacingOccurrences(of: "\"\"", with: "\"")
        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    private static func cleanISBN(_ value: String) -> String? {
        var cleaned = value
        if cleaned.hasPrefix("=") && cleaned.hasPrefix("\"") {
            cleaned = String(cleaned.dropFirst())
        }
        cleaned = cleaned.replacingOccurrences(of: "\"", with: "")
        cleaned = cleaned.replacingOccurrences(of: "=", with: "")
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func getValue(for header: String, headers: [String], values: [String]) -> String? {
        guard let index = headers.firstIndex(of: header),
              index < values.count else { return nil }
        let value = values[index]
        return value.isEmpty ? nil : cleanGoodreadsValue(value)
    }

    static func mapToResourceEntity(_ book: GoodreadsCSVBook) -> ResourceEntity {
        let status = mapShelfToStatus(book.exclusiveShelf)

        return ResourceEntity(
            type: .book,
            title: book.title,
            externalId: book.isbn13 ?? book.isbn,
            authorOrCreator: book.author,
            userRating: book.myRating,
            status: status,
            lastUpdated: Date(),
            totalPages: book.numberOfPages,
            endDate: book.dateRead
        )
    }

    private static func mapShelfToStatus(_ shelf: String) -> ProgressStatus {
        switch shelf.lowercased() {
        case "read":
            return .completed
        case "currently-reading":
            return .inProgress
        case "to-read":
            return .wishlist
        default:
            return .notStarted
        }
    }
}

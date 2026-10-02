import XCTest
import SwiftData
import UIKit
@testable import TrackHobbies

final class CSVExporterTests: XCTestCase {
    func testNilFieldsAreEmptyNotZero() {
        let csv = CSVExporter.export([ResourceEntity(type: .game, title: "Hades")])
        let row = CSVImporter.parseRows(csv)[1]
        XCTAssertEqual(row.count, CSVImporter.parseRows(csv)[0].count)
        XCTAssertEqual(row.filter { !$0.isEmpty }, ["game", "Hades", "not_started"])
    }

    func testQuotesAndNewlinesStayInsideField() {
        let e = ResourceEntity(type: .book, title: "Say \"hi\"", reviewComment: "a\nb")
        let csv = CSVExporter.export([e])
        XCTAssertTrue(csv.contains("\"Say \"\"hi\"\"\""))
        XCTAssertEqual(CSVImporter.parse(csv).first?.reviewComment, "a\nb")
    }

    func testRoundTripKeepsProgressStatusAndCover() {
        let e = ResourceEntity(type: .series, title: "Dark, S1", externalId: "42", imageURL: "https://x/y.jpg",
                               userRating: 4.25, status: .inProgress, currentSeason: 2, currentEpisode: 3,
                               totalSeasons: 3, startDate: Date(timeIntervalSince1970: 1_700_000_000), reviewComment: "a\nb")
        let back = CSVImporter.parse(CSVExporter.export([e]))
        XCTAssertEqual(back.count, 1)
        XCTAssertEqual(back[0].title, "Dark, S1")
        XCTAssertEqual(back[0].imageURL, "https://x/y.jpg")
        XCTAssertEqual(back[0].progressStatus, .inProgress)
        XCTAssertEqual(back[0].userRating, 4.25)
        XCTAssertEqual(back[0].currentEpisode, 3)
        XCTAssertEqual(back[0].reviewComment, "a\nb")
        XCTAssertNotNil(back[0].startDate)
    }
}

final class BookMatchTests: XCTestCase {
    private func item(_ title: String, _ author: String, pages: Int? = nil, cover: String? = nil) -> GoogleBookItem {
        GoogleBookItem(title: title, author: author, coverURL: cover, externalId: UUID().uuidString, numberOfPages: pages, summary: nil)
    }

    func testCleanTitleDropsSeries() {
        XCTAssertEqual(BookMatch.cleanTitle("The Hobbit (The Lord of the Rings, #0)"), "The Hobbit")
        XCTAssertEqual(BookMatch.cleanTitle("Dune"), "Dune")
    }

    func testPickMatchesTitleAndAuthorAndPrefersPagesAndCover() {
        let r = [item("Dune Messiah", "Frank Herbert", pages: 300),
                 item("Otro libro", "Alguien", pages: 100, cover: "c"),
                 item("Dune", "Frank Herbert"),
                 item("Dune", "Frank Herbert", pages: 412, cover: "c")]
        XCTAssertEqual(BookMatch.pick(r, title: "Dune (Dune Chronicles, #1)", author: "Frank Herbert")?.numberOfPages, 412)
    }

    func testStripSeriesOnlyRemovesGoodreadsSeriesSuffix() {
        XCTAssertEqual(BookMatch.stripSeries("Dune (Dune Chronicles, #1)"), "Dune")
        XCTAssertEqual(BookMatch.stripSeries("The Hobbit (The Lord of the Rings #0)"), "The Hobbit")
        XCTAssertEqual(BookMatch.stripSeries("Brave New World (Annotated)"), "Brave New World (Annotated)")
        XCTAssertEqual(BookMatch.stripSeries("Dune"), "Dune")
        XCTAssertEqual(BookMatch.stripSeries("Catch-22 (Catch-22, #1) (Special)"), "Catch-22 (Catch-22, #1) (Special)")
    }

    func testQueryIsPlainTextWithoutOperators() {
        XCTAssertEqual(BookMatch.query(title: "Hyperion (Hyperion Cantos, #1)", author: "Dan Simmons"), "Hyperion Dan Simmons")
        XCTAssertEqual(BookMatch.query(title: "Dune", author: nil), "Dune")
        XCTAssertFalse(BookMatch.query(title: "A \"B\"", author: "C").contains(":"))
    }

    func testPickReturnsNilWhenNothingFits() {
        XCTAssertNil(BookMatch.pick([item("Otro", "Alguien", pages: 10)], title: "Dune", author: "Frank Herbert"))
        XCTAssertNil(BookMatch.pick([item("Dune", "Isaac Asimov", pages: 10)], title: "Dune", author: "Frank Herbert"))
    }
}

final class ManualEntryTests: XCTestCase {
    func testCoverDataURLRoundTripsAndShrinks() throws {
        let big = UIGraphicsImageRenderer(size: CGSize(width: 2000, height: 3000)).image { ctx in
            UIColor.red.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 2000, height: 3000))
        }
        let url = try XCTUnwrap(CoverStore.dataURL(from: big.pngData()!))
        let back = try XCTUnwrap(CoverStore.decode(url))
        XCTAssertEqual(max(back.size.width, back.size.height), 480, accuracy: 1)
        XCTAssertLessThan(url.count, 100_000)
        XCTAssertNil(CoverStore.decode("https://x/y.jpg"))
    }

    @MainActor
    func testDraftBuildsEntityPerType() throws {
        let container = try ModelContainer(for: ResourceEntity.self, PendingItemEntity.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        var d = ManualDraft(title: "  Dark  ", status: .inProgress, pages: "99", seasons: "3", episodes: "26")
        let s = d.insert(type: .series, context: container.mainContext)
        XCTAssertEqual(s.title, "Dark")
        XCTAssertEqual(s.totalSeasons, 3)
        XCTAssertNil(s.totalPages) // las páginas no aplican a series
        XCTAssertNotNil(s.startDate)
        d.status = .completed
        let book = d.insert(type: .book, context: container.mainContext)
        XCTAssertNotNil(book.endDate)
        XCTAssertEqual(book.totalPages, 99)
        XCTAssertNil(book.totalSeasons) // las temporadas no aplican a libros
        XCTAssertFalse(ManualDraft(title: "  ").isValid)
    }
}

final class BackupTests: XCTestCase {
    func testRoundTripKeepsEveryField() throws {
        let e = ResourceEntity(type: .book, title: "Dune", externalId: "x", imageURL: "data:image/jpeg;base64,AAAA",
                               summary: "s", authorOrCreator: "FH", userRating: 4.75, status: .inProgress,
                               timeSpentHours: 2.5, lastUpdated: Date(timeIntervalSince1970: 1_700_000_000),
                               currentPage: 10, totalPages: 400, progressPercentage: 2.5, currentSeason: 1,
                               currentEpisode: 2, totalSeasons: 3, totalEpisodes: 9,
                               startDate: Date(timeIntervalSince1970: 1_690_000_000), reviewComment: "a\nb")
        let back = try XCTUnwrap(Backup.decode(Backup.encode([e])).first)
        XCTAssertEqual(back.id, e.id)
        XCTAssertEqual(Backup.Item(back).imageURL, e.imageURL)
        XCTAssertEqual(back.progressStatus, .inProgress)
        XCTAssertEqual(back.userRating, 4.75)
        XCTAssertEqual(back.totalEpisodes, 9)
        XCTAssertEqual(back.startDate, e.startDate)
        XCTAssertEqual(back.reviewComment, "a\nb")
    }

    func testRejectsGarbageAndNewerVersions() {
        XCTAssertThrowsError(try Backup.decode(Data("nope".utf8)))
        let newer = #"{"version":99,"exportedAt":"2026-01-01T00:00:00Z","items":[]}"#
        XCTAssertThrowsError(try Backup.decode(Data(newer.utf8)))
    }
}

final class GoodreadsImportTests: XCTestCase {
    // Formato real del export «Mis libros» de Goodreads: 24 columnas, ISBN como ="…", reseña con
    // salto de línea y comillas dentro del campo, rating 0 = sin puntuar, estantería personalizada.
    private let sample = #"""
    Book Id,Title,Author,Author l-f,Additional Authors,ISBN,ISBN13,My Rating,Average Rating,Publisher,Binding,Number of Pages,Year Published,Original Publication Year,Date Read,Date Added,Bookshelves,Bookshelves with positions,Exclusive Shelf,My Review,Spoiler,Private Notes,Read Count,Owned Copies
    123,"Dune (Dune Chronicles, #1)",Frank Herbert,"Herbert, Frank",,"=""0441172717""","=""9780441172719""",5,4.27,Ace,Paperback,604,1990,1965,2023/05/14,2023/01/02,"sci-fi, favorites","sci-fi (#1), favorites (#2)",read,"Obra maestra.<br/>Segunda línea
    y una tercera con ""comillas"".",,,1,0
    456,"El nombre del viento",Patrick Rothfuss,"Rothfuss, Patrick",,"=""""","=""""",0,4.5,,,662,2007,2007,,2023/03/03,,,to-read,,,,0,0
    789,Neuromancer,William Gibson,"Gibson, William",,"=""0441569595""","=""9780441569595""",4,3.9,Ace,Paperback,271,1984,1984,,2023/04/04,cyberpunk,cyberpunk (#1),currently-reading,,,,0,0
    """#

    func testParsesRealExportIncludingMultilineReview() throws {
        let books = GoodreadsImporter.parse(csvContent: sample)
        XCTAssertEqual(books.count, 3) // el salto de línea de la reseña no parte la fila
        let dune = books[0]
        XCTAssertEqual(dune.title, "Dune (Dune Chronicles, #1)")
        XCTAssertEqual(dune.isbn, "0441172717")
        XCTAssertEqual(dune.isbn13, "9780441172719")
        XCTAssertEqual(dune.myRating, 5)
        XCTAssertEqual(dune.numberOfPages, 604)
        XCTAssertNotNil(dune.dateRead)
        XCTAssertEqual(dune.review, "Obra maestra.\nSegunda línea\ny una tercera con \"comillas\".")
    }

    func testUnratedAndEmptyIsbnBecomeNil() {
        let rothfuss = GoodreadsImporter.parse(csvContent: sample)[1]
        XCTAssertNil(rothfuss.myRating) // 0 en Goodreads = sin puntuar
        XCTAssertNil(rothfuss.isbn)
        XCTAssertNil(rothfuss.isbn13)
        XCTAssertNil(rothfuss.dateRead)
    }

    func testShelvesMapToStatus() {
        let e = GoodreadsImporter.parse(csvContent: sample).map(GoodreadsImporter.mapToResourceEntity)
        XCTAssertEqual(e.map(\.progressStatus), [.completed, .wishlist, .inProgress])
        XCTAssertEqual(e[0].title, "Dune") // sin el sufijo de serie
        XCTAssertEqual(e[0].externalId, "9780441172719")
        XCTAssertEqual(e[0].reviewComment?.hasPrefix("Obra maestra."), true)
    }

    func testHandlesBOMAndWindowsLineEndings() {
        let csv = "\u{FEFF}" + sample.replacingOccurrences(of: "\n", with: "\r\n")
        XCTAssertEqual(GoodreadsImporter.parse(csvContent: csv).count, 3)
    }

    func testDedupeKeyIgnoresSeriesCaseAndAccents() {
        XCTAssertEqual(GoodreadsImporter.dedupeKey(title: "Dune (Dune Chronicles, #1)", author: "Frank Herbert"),
                       GoodreadsImporter.dedupeKey(title: "DUNE", author: "frank herbert"))
        XCTAssertNotEqual(GoodreadsImporter.dedupeKey(title: "Dune", author: "Frank Herbert"),
                          GoodreadsImporter.dedupeKey(title: "Dune", author: "Otro Autor"))
    }

    func testNotAGoodreadsFileGivesNothing() {
        XCTAssertTrue(GoodreadsImporter.parse(csvContent: "a,b\n1,2").isEmpty)
        XCTAssertTrue(GoodreadsImporter.parse(csvContent: "").isEmpty)
    }
}

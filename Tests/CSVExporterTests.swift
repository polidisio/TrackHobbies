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

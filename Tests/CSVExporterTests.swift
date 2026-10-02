import XCTest
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
        XCTAssertTrue(csv.hasSuffix("\"a\nb\""))
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

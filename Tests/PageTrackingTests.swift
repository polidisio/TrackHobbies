import XCTest
@testable import TrackHobbies

final class PageTrackingTests: XCTestCase {
    func testValidateTotal() {
        XCTAssertEqual(PageTracking.validateTotal("350", currentPage: 120), .success(350))
        XCTAssertEqual(PageTracking.validateTotal(" 350 ", currentPage: nil), .success(350))
        XCTAssertEqual(PageTracking.validateTotal("120", currentPage: 120), .success(120))
        XCTAssertEqual(PageTracking.validateTotal("3", currentPage: 120), .failure(.belowCurrent(120)))
        for bad in ["", "abc", "0", "-5", "10001", "3.5"] {
            XCTAssertEqual(PageTracking.validateTotal(bad, currentPage: nil), .failure(.invalid), bad)
        }
    }

    func testClampedPage() {
        XCTAssertEqual(PageTracking.clampedPage(400, total: 350), 350)
        XCTAssertEqual(PageTracking.clampedPage(400, total: nil), 400)
        XCTAssertEqual(PageTracking.clampedPage(-3, total: 350), 0)
    }

    /// Caso del bug: libro sin total, página 120 y luego se teclea el total "3", "35", "350".
    func testNoCompletionWithoutTotalOrWhileTypingTotal() {
        XCTAssertFalse(PageTracking.isFinished(page: 120, total: nil))
        XCTAssertFalse(PageTracking.isFinished(page: 120, total: 0))
        XCTAssertFalse(PageTracking.isFinished(page: 119, total: 350))
        XCTAssertTrue(PageTracking.isFinished(page: 350, total: 350))
        // El total solo se aplica si es válido: "3" y "35" se rechazan frente a la página 120.
        XCTAssertEqual(PageTracking.validateTotal("3", currentPage: 120), .failure(.belowCurrent(120)))
        XCTAssertEqual(PageTracking.validateTotal("35", currentPage: 120), .failure(.belowCurrent(120)))
    }
}

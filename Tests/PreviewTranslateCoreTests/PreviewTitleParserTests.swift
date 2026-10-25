import XCTest
@testable import PreviewTranslateCore

final class PreviewTitleParserTests: XCTestCase {
    func testParsesKoreanLocalizedTitle() {
        // Arrange: the exact title this Mac shows for the open PDF.
        let title = "Hands-On.pdf – 861/1,126페이지"

        // Act
        let info = PreviewTitleParser.parse(title)

        // Assert
        XCTAssertEqual(info.page, 861)
        XCTAssertEqual(info.pageCount, 1126)
    }

    func testParsesEnglishPageOfTitle() {
        let info = PreviewTitleParser.parse("Report.pdf – Page 3 of 12")
        XCTAssertEqual(info.page, 3)
        XCTAssertEqual(info.pageCount, 12)
    }

    func testIgnoresSlashInsideFileName() {
        // Arrange: a filename date must not be mistaken for the position.
        let title = "invoice 2024/03 – 5/9페이지"

        // Act
        let info = PreviewTitleParser.parse(title)

        // Assert
        XCTAssertEqual(info.page, 5)
        XCTAssertEqual(info.pageCount, 9)
    }

    func testReturnsUnknownWhenNoPositionPresent() {
        let info = PreviewTitleParser.parse("Untitled.pdf")
        XCTAssertNil(info.page)
        XCTAssertNil(info.pageCount)
    }

    func testRejectsImpossiblePageNumbers() {
        let info = PreviewTitleParser.parse("Odd.pdf – 40/10페이지")
        XCTAssertNil(info.page)
    }
}

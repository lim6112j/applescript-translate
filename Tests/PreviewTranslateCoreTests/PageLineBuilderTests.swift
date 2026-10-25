import XCTest
@testable import PreviewTranslateCore

final class PageLineBuilderTests: XCTestCase {
    func testJoinsRunsBrokenByInlineLink() {
        // Arrange: PDFKit splits a sentence around a linked "Figure 18-2".
        // The newline comes only at the end of the visual line.
        let runs = [
            TextRun(text: "The policy could be a neural network taking observations as inputs and outputting the action to take (see ", fontSize: 10, isBold: false),
            TextRun(text: "Figure 18-2", fontSize: 10, isBold: false),
            TextRun(text: ").\n", fontSize: 10, isBold: false),
        ]

        // Act
        let lines = PageLineBuilder.lines(from: runs)

        // Assert
        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0].text, "The policy could be a neural network taking observations as inputs and outputting the action to take (see Figure 18-2).")
    }

    func testKeepsSeparateLinesSeparate() {
        let runs = [
            TextRun(text: "Policy Search\n", fontSize: 14.2, isBold: false),
            TextRun(text: "The algorithm is called its policy.\n", fontSize: 10, isBold: false),
        ]

        let lines = PageLineBuilder.lines(from: runs)

        XCTAssertEqual(lines.map(\.text), ["Policy Search", "The algorithm is called its policy."])
        XCTAssertEqual(lines[0].fontSize, 14.2)
    }

    func testDominantFontDecidesLineStyle() {
        // Arrange: a short bold link inside a longer regular line.
        let runs = [
            TextRun(text: "See this reference for details about the policy definition ", fontSize: 10, isBold: false),
            TextRun(text: "here", fontSize: 10, isBold: true),
            TextRun(text: "\n", fontSize: 10, isBold: false),
        ]

        // Act
        let lines = PageLineBuilder.lines(from: runs)

        // Assert
        XCTAssertEqual(lines.count, 1)
        XCTAssertFalse(lines[0].isBold)
    }

    func testDropsEmptyLines() {
        let runs = [
            TextRun(text: "\n\n", fontSize: 10, isBold: false),
            TextRun(text: "Real line.\n", fontSize: 10, isBold: false),
        ]

        XCTAssertEqual(PageLineBuilder.lines(from: runs).map(\.text), ["Real line."])
    }

    func testStripsFootnoteMarkersFromRebuiltLines() {
        // Arrange: a superscript footnote number sits on its own run.
        let runs = [
            TextRun(text: "applications over the years,\u{2060}\n", fontSize: 10, isBold: false),
            TextRun(text: "1\n", fontSize: 5.8, isBold: false),
            TextRun(text: "particularly in games.\n", fontSize: 10, isBold: false),
        ]

        let lines = PageLineBuilder.lines(from: runs)

        XCTAssertEqual(lines.map(\.text), ["applications over the years,", "particularly in games."])
    }
}

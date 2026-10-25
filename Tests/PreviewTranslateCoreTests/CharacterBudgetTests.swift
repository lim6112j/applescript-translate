import XCTest
@testable import PreviewTranslateCore

final class CharacterBudgetTests: XCTestCase {
    func testKeepsAllBlocksThatFit() {
        let blocks = ["First paragraph.", "Second paragraph."]
        XCTAssertEqual(CharacterBudget.fit(blocks, to: 100), blocks)
    }

    func testIncludesPartialSentenceOfTheOverflowingParagraph() {
        // Arrange: the second paragraph only partly fits.
        let blocks = [
            "Short one.",
            "This second paragraph has several sentences. Only the first one fits. The rest must be dropped.",
        ]

        // Act
        let fitted = CharacterBudget.fit(blocks, to: 60)

        // Assert: only the first sentence of the second paragraph fits in 49 chars,
        // and it is still a complete sentence.
        XCTAssertEqual(fitted.count, 2)
        XCTAssertEqual(fitted[1], "This second paragraph has several sentences.")
        XCTAssertLessThanOrEqual(fitted[1].count, 60 - blocks[0].count - 1)
    }

    func testTruncatesSingleOversizedParagraphOnSentenceBoundary() {
        let block = "First sentence is here. Second sentence follows. Third is last."
        let fitted = CharacterBudget.fit([block], to: 30)

        XCTAssertEqual(fitted, ["First sentence is here."])
    }

    func testReturnsEmptyForEmptyInputOrZeroBudget() {
        XCTAssertTrue(CharacterBudget.fit([], to: 100).isEmpty)
        XCTAssertTrue(CharacterBudget.fit(["text"], to: 0).isEmpty)
    }

    func testBudgetLargerThanContentKeepsEverything() {
        let blocks = ["Alpha.", "Beta.", "Gamma."]
        XCTAssertEqual(CharacterBudget.fit(blocks, to: 10_000), blocks)
    }
}

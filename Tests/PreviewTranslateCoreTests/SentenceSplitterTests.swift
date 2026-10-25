import XCTest
@testable import PreviewTranslateCore

final class SentenceSplitterTests: XCTestCase {
    func testSplitsOnSentenceBoundaries() {
        // Arrange
        let text = "Reinforcement learning is exciting. It is also old! Is it useful? Yes."

        // Act
        let sentences = SentenceSplitter.split(text)

        // Assert
        XCTAssertEqual(sentences.count, 4)
        XCTAssertEqual(sentences.first, "Reinforcement learning is exciting.")
        XCTAssertEqual(sentences.last, "Yes.")
    }

    func testDoesNotSplitOnAbbreviations() {
        // Arrange
        let text = "Use e.g. a robot or a thermostat. Both work well."

        // Act
        let sentences = SentenceSplitter.split(text)

        // Assert
        XCTAssertEqual(sentences.count, 2)
        XCTAssertTrue(sentences[0].contains("e.g."))
    }

    func testEmptyInputReturnsEmptyArray() {
        XCTAssertTrue(SentenceSplitter.split("   ").isEmpty)
    }

    func testTextWithoutTerminalPunctuationStillReturnsOneSentence() {
        XCTAssertEqual(SentenceSplitter.split("Figure 18-1 shows an example"), ["Figure 18-1 shows an example"])
    }
}

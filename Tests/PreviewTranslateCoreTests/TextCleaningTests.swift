import XCTest
@testable import PreviewTranslateCore

final class TextCleaningTests: XCTestCase {
    func testRemovesWordJoinersAndLoneMarkerLines() {
        // Arrange: what PDFKit actually produced for the page under test.
        let raw = "Chapter 18. Reinforcement Learning\nReinforcement learning (RL) is one of the\u{2060}\n1\noldest fields.\n2\nDeepMind showed it."

        // Act
        let cleaned = TextCleaning.cleanPageText(raw)

        // Assert
        XCTAssertEqual(cleaned, "Chapter 18. Reinforcement Learning Reinforcement learning (RL) is one of the oldest fields. DeepMind showed it.")
        XCTAssertFalse(cleaned.contains("\u{2060}"))
    }

    func testKeepsMeaningfulShortLines() {
        // Arrange: a short line that is not just a marker must survive.
        let raw = "Fig. 18-1\nReinforcement learning is described in this chapter."

        // Act
        let cleaned = TextCleaning.cleanPageText(raw)

        // Assert
        XCTAssertTrue(cleaned.contains("Fig. 18-1"))
    }

    func testRejoinsHyphenatedLineBreak() {
        // Arrange: "Q-" ended one line and "networks" began the next.
        let raw = "deep Q-\nnetworks are used here."

        // Act
        let cleaned = TextCleaning.cleanPageText(raw)

        // Assert
        XCTAssertEqual(cleaned, "deep Q-networks are used here.")
    }

    func testCollapsesWhitespaceAroundPunctuation() {
        // Arrange
        let raw = "This is a sentence .\nNext ( item ) here ."

        // Act
        let cleaned = TextCleaning.cleanPageText(raw)

        // Assert
        XCTAssertEqual(cleaned, "This is a sentence. Next (item) here.")
    }

    func testEmptyInputProducesEmptyOutput() {
        XCTAssertEqual(TextCleaning.cleanPageText(""), "")
        XCTAssertEqual(TextCleaning.cleanPageText("\n\n  \n"), "")
    }
}

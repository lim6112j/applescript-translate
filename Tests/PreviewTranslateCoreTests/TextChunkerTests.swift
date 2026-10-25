import XCTest
@testable import PreviewTranslateCore

final class TextChunkerTests: XCTestCase {
    func testGroupsSentencesUpToLimit() {
        // Arrange
        let text = "First sentence here. Second sentence here. Third sentence here."

        // Act
        let chunks = TextChunker.chunks(of: text, maxCharacters: 40)

        // Assert: every chunk respects the budget and no sentence is split.
        XCTAssertFalse(chunks.isEmpty)
        for chunk in chunks {
            XCTAssertLessThanOrEqual(chunk.count, 40)
            XCTAssertTrue(text.contains(chunk))
        }
    }

    func testKeepsAllWordsInOrder() {
        // Arrange
        let text = (1...20).map { "Sentence number \($0) is short." }.joined(separator: " ")

        // Act
        let joined = TextChunker.chunks(of: text, maxCharacters: 60).joined(separator: " ")

        // Assert
        XCTAssertEqual(joined, text)
    }

    func testHardSplitsOverLongSentenceAtWordBoundary() {
        // Arrange
        let sentence = String(repeating: "word ", count: 40).trimmingCharacters(in: .whitespaces)

        // Act
        let chunks = TextChunker.chunks(of: sentence, maxCharacters: 25)

        // Assert
        XCTAssertGreaterThan(chunks.count, 1)
        for chunk in chunks {
            XCTAssertLessThanOrEqual(chunk.count, 25)
            XCTAssertFalse(chunk.hasPrefix(" "))
        }
        XCTAssertEqual(chunks.joined(separator: " "), sentence)
    }

    func testEmptyTextProducesNoChunks() {
        XCTAssertTrue(TextChunker.chunks(of: "").isEmpty)
    }

    func testShortTextStaysInOneChunk() {
        XCTAssertEqual(TextChunker.chunks(of: "One short sentence."), ["One short sentence."])
    }
}

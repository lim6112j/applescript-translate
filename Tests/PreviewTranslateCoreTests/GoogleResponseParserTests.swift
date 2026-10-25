import XCTest
@testable import PreviewTranslateCore

final class GoogleResponseParserTests: XCTestCase {
    func testParsesSegmentsIntoAlignedPairs() throws {
        // Arrange: the shape translate_a/single returns, trimmed to the fields we use.
        let json = """
        [[["강화 학습은 흥미롭다.","Reinforcement learning is exciting.",null,null,3],
          ["그것은 오래되었다.","It is old.",null,null,3]],null,"en"]
        """.data(using: .utf8)!

        // Act
        let pairs = try GoogleResponseParser.pairs(from: json)

        // Assert
        XCTAssertEqual(pairs, [
            TranslationPair(source: "Reinforcement learning is exciting.", target: "강화 학습은 흥미롭다."),
            TranslationPair(source: "It is old.", target: "그것은 오래되었다."),
        ])
    }

    func testRejectsHTMLBlockPage() {
        // Arrange: Google answers with an HTML "Sorry..." page when it rate-limits.
        let html = "<html><head><title>Sorry...</title></head></html>".data(using: .utf8)!

        // Act / Assert
        XCTAssertThrowsError(try GoogleResponseParser.pairs(from: html)) { error in
            XCTAssertEqual(error as? GoogleResponseParser.ParseError, .htmlResponse)
        }
    }

    func testRejectsEmptySegmentList() {
        let json = "[[],null,\"en\"]".data(using: .utf8)!
        XCTAssertThrowsError(try GoogleResponseParser.pairs(from: json))
    }

    func testSkipsSegmentsMissingTranslation() throws {
        // Arrange: trailing segments can carry null translations.
        let json = """
        [[["번역","Source here.",null,null,3],[null,"Fragment",null,null,3]]]
        """.data(using: .utf8)!

        // Act
        let pairs = try GoogleResponseParser.pairs(from: json)

        // Assert
        XCTAssertEqual(pairs.count, 1)
        XCTAssertEqual(pairs.first?.target, "번역")
    }

    func testRejectsMalformedJSON() {
        let data = "not json".data(using: .utf8)!
        XCTAssertThrowsError(try GoogleResponseParser.pairs(from: data))
    }
}

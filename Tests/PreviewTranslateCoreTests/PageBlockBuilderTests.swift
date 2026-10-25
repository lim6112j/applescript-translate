import XCTest
@testable import PreviewTranslateCore

final class PageBlockBuilderTests: XCTestCase {
    func testSeparatesHeadingFromParagraph() {
        // Arrange: font sizes taken from page 862 of the sample PDF.
        let lines = [
            PageLine(text: "Policy Search", fontSize: 14.2, isBold: false),
            PageLine(text: "The algorithm a software agent uses to determine", fontSize: 10, isBold: false),
            PageLine(text: "its actions is called its policy.", fontSize: 10, isBold: false),
        ]

        // Act
        let blocks = PageBlockBuilder.blocks(from: lines)

        // Assert
        XCTAssertEqual(blocks, [
            "Policy Search",
            "The algorithm a software agent uses to determine its actions is called its policy.",
        ])
    }

    func testStandaloneCaptionDoesNotAbsorbFollowingText() {
        // Arrange
        let lines = [
            PageLine(text: "Figure 18-2. Reinforcement learning using a neural network policy", fontSize: 7.5, isBold: false),
            PageLine(text: "The policy can be any algorithm you can think of.", fontSize: 10, isBold: false),
            PageLine(text: "It does not have to be deterministic.", fontSize: 10, isBold: false),
        ]

        // Act
        let blocks = PageBlockBuilder.blocks(from: lines)

        // Assert
        XCTAssertEqual(blocks.count, 2)
        XCTAssertTrue(blocks.first?.hasPrefix("Figure 18-2.") ?? false)
        XCTAssertTrue(blocks.last?.hasPrefix("The policy") ?? false)
    }

    func testBoldBodySizeLineIsTreatedAsHeading() {
        let lines = [
            PageLine(text: "Learning to Optimize Rewards", fontSize: 10, isBold: true),
            PageLine(text: "Body text follows here.", fontSize: 10, isBold: false),
        ]

        let blocks = PageBlockBuilder.blocks(from: lines)

        XCTAssertEqual(blocks, ["Learning to Optimize Rewards", "Body text follows here."])
    }

    func testBodyFontSizeUsesMedian() {
        let lines = [
            PageLine(text: "a", fontSize: 7.5, isBold: false),
            PageLine(text: "b", fontSize: 10, isBold: false),
            PageLine(text: "c", fontSize: 10, isBold: false),
            PageLine(text: "d", fontSize: 14.2, isBold: false),
        ]

        XCTAssertEqual(PageLineClassifier.bodyFontSize(of: lines), 10)
    }

    func testEmptyLinesAreDropped() {
        let lines = [
            PageLine(text: "", fontSize: 10, isBold: false),
            PageLine(text: "   ", fontSize: 10, isBold: false),
            PageLine(text: "Only line.", fontSize: 10, isBold: false),
        ]

        XCTAssertEqual(PageBlockBuilder.blocks(from: lines), ["Only line."])
    }
}

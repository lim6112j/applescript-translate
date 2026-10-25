import Foundation

public struct PageLine: Equatable {
    public let text: String
    public let fontSize: CGFloat
    public let isBold: Bool

    public init(text: String, fontSize: CGFloat, isBold: Bool) {
        self.text = text
        self.fontSize = fontSize
        self.isBold = isBold
    }
}

/// Uses font information to decide which lines are headings or captions, which
/// plain text extraction cannot reveal.
public enum PageLineClassifier {
    /// A line this much larger than the page's body size is a heading.
    public static let headingScale: CGFloat = 1.15

    public static func bodyFontSize(of lines: [PageLine]) -> CGFloat {
        let sizes = lines
            .map(\.fontSize)
            .filter { $0 > 0 }
            .sorted()
        guard !sizes.isEmpty else { return 0 }
        return sizes[sizes.count / 2]
    }

    private static let captionPrefixes = ["figure", "fig.", "table", "algorithm", "listing", "그림", "표"]

    /// True for headings and captions. Those read better as their own block, without
    /// being merged into the following paragraph.
    public static func isStandalone(_ line: PageLine, bodySize: CGFloat) -> Bool {
        guard !line.text.isEmpty else { return false }
        if isFootnoteMarker(line, bodySize: bodySize) { return true }
        if line.isBold && line.fontSize >= bodySize { return true }
        if bodySize > 0 && line.fontSize >= bodySize * headingScale { return true }
        return isCaption(line.text)
    }

    /// A lone superscript number (`1`, `12`) between paragraphs is a footnote callout,
    /// not a sentence. It must not be merged into the paragraph that follows.
    static func isFootnoteMarker(_ line: PageLine, bodySize: CGFloat) -> Bool {
        guard bodySize > 0, line.fontSize > 0, line.fontSize < bodySize * 0.95 else { return false }
        let text = line.text.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, text.count <= 3 else { return false }
        return text.allSatisfy(\.isNumber)
    }

    static func isCaption(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return captionPrefixes.contains { lowered.hasPrefix($0 + " ") }
    }
}

/// Groups a page's lines into paragraphs: consecutive body lines are joined, while
/// headings and captions become standalone blocks.
public enum PageBlockBuilder {
    public static func blocks(from lines: [PageLine]) -> [String] {
        let bodySize = PageLineClassifier.bodyFontSize(of: lines)
        var blocks: [String] = []
        var paragraph = ""

        func flushParagraph() {
            if !paragraph.isEmpty {
                blocks.append(paragraph)
                paragraph = ""
            }
        }

        for line in lines {
            let text = line.text.trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { continue }

            if PageLineClassifier.isStandalone(line, bodySize: bodySize) {
                flushParagraph()
                blocks.append(text)
                continue
            }

            paragraph = paragraph.isEmpty ? text : paragraph + " " + text
        }
        flushParagraph()

        return blocks
    }
}

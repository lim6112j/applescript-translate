import Foundation

/// One attributed run of text from a PDF page.
public struct TextRun: Equatable {
    public let text: String
    public let fontSize: CGFloat
    public let isBold: Bool

    public init(text: String, fontSize: CGFloat, isBold: Bool) {
        self.text = text
        self.fontSize = fontSize
        self.isBold = isBold
    }
}

/// Rebuilds visual lines from runs. A link or italic word splits a line into several
/// runs, so lines must be joined again at newline boundaries before classifying them.
public enum PageLineBuilder {
    public static func lines(from runs: [TextRun]) -> [PageLine] {
        var lines: [PageLine] = []
        var buffer: [TextRun] = []

        func flush() {
            guard !buffer.isEmpty else { return }
            let text = TextCleaning.cleanPageText(buffer.map(\.text).joined())
            if !text.isEmpty {
                let dominant = dominantRun(in: buffer)
                lines.append(PageLine(text: text, fontSize: dominant.fontSize, isBold: dominant.isBold))
            }
            buffer.removeAll()
        }

        for run in runs {
            let pieces = run.text.components(separatedBy: "\n")
            for (index, piece) in pieces.enumerated() {
                if index > 0 {
                    flush()
                }
                guard !piece.isEmpty else { continue }
                buffer.append(TextRun(text: piece, fontSize: run.fontSize, isBold: run.isBold))
            }
        }
        flush()

        return lines
    }

    /// The font of the run carrying most of the characters: a bold word or a linked
    /// figure number should not reclassify the whole line.
    private static func dominantRun(in runs: [TextRun]) -> TextRun {
        runs.max { $0.text.count < $1.text.count } ?? runs[0]
    }
}

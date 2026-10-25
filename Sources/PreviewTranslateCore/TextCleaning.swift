import Foundation

/// Turns the newline-per-line text that PDFKit returns into one flowing string
/// that a translation engine can handle well.
public enum TextCleaning {
    /// Invisible characters PDF producers inject (word joiner after footnote markers,
    /// zero-width spaces, soft hyphens) would otherwise reach the translator.
    private static let invisibleCharacters: [String] = [
        "\u{2060}", // WORD JOINER
        "\u{200B}", // ZERO WIDTH SPACE
        "\u{FEFF}", // ZERO WIDTH NO-BREAK SPACE / BOM
        "\u{00AD}", // SOFT HYPHEN
    ]

    /// Lines that contain nothing but a footnote marker, list number or page number.
    private static let markerCharacters = CharacterSet(charactersIn: "0123456789.,-–—†‡*•·+ ")

    public static func cleanPageText(_ raw: String) -> String {
        var text = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        for character in invisibleCharacters {
            text = text.replacingOccurrences(of: character, with: "")
        }

        let keptLines = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !isMarkerOnlyLine($0) }

        text = keptLines.joined(separator: " ")
        text = rejoinHyphenatedLineBreaks(text)
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\s+([,.;:!?)\\]])", with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: "([(\\[])\\s+", with: "$1", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `Q- networks` came from a line break inside a hyphenated word.
    static func rejoinHyphenatedLineBreaks(_ text: String) -> String {
        text.replacingOccurrences(
            of: "([A-Za-z])-[ ]+([a-z])",
            with: "$1-$2",
            options: .regularExpression
        )
    }

    static func isMarkerOnlyLine(_ line: String) -> Bool {
        guard !line.isEmpty, line.count <= 6 else { return false }
        let scalars = line.unicodeScalars
        guard scalars.allSatisfy({ markerCharacters.contains($0) }) else { return false }
        return scalars.contains { CharacterSet.decimalDigits.contains($0) }
    }
}

import AppKit
import PDFKit
import PreviewTranslateCore

/// Extracts a page as font-aware lines so headings and captions survive intact.
/// Must run on the PDF queue (see `TranslationService`).
enum PDFPageTextExtractor {
    static func lines(from page: PDFPage) -> [PageLine] {
        guard let attributed = page.attributedString, attributed.length > 0 else {
            return fallbackLines(from: page)
        }

        var runs: [TextRun] = []
        attributed.enumerateAttributes(in: NSRange(location: 0, length: attributed.length)) { attributes, range, _ in
            let text = (attributed.string as NSString).substring(with: range)
            guard !text.isEmpty else { return }
            let font = attributes[.font] as? NSFont
            runs.append(TextRun(
                text: text,
                fontSize: font?.pointSize ?? 0,
                isBold: font.map(isBoldFont) ?? false
            ))
        }

        let lines = PageLineBuilder.lines(from: runs)
        return lines.isEmpty ? fallbackLines(from: page) : lines
    }

    private static func fallbackLines(from page: PDFPage) -> [PageLine] {
        guard let text = page.string else { return [] }
        return text
            .components(separatedBy: .newlines)
            .compactMap { raw -> PageLine? in
                let cleaned = TextCleaning.cleanPageText(raw)
                return cleaned.isEmpty ? nil : PageLine(text: cleaned, fontSize: 0, isBold: false)
            }
    }

    private static func isBoldFont(_ font: NSFont) -> Bool {
        let traits = font.fontDescriptor.symbolicTraits
        if traits.contains(.bold) { return true }
        return font.fontName.lowercased().contains("bold")
    }
}

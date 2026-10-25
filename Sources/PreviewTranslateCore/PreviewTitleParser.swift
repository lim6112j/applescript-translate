import Foundation

public struct PreviewPageInfo: Equatable {
    public let page: Int?
    public let pageCount: Int?

    public init(page: Int?, pageCount: Int?) {
        self.page = page
        self.pageCount = pageCount
    }

    public static let unknown = PreviewPageInfo(page: nil, pageCount: nil)
}

/// Preview puts the position in the window title, e.g.
/// `Hands-On.pdf – 861/1,126페이지` or `Report.pdf – Page 3 of 12`.
public enum PreviewTitleParser {
    private static let slashPattern = "(\\d[\\d,.]*)\\s*/\\s*(\\d[\\d,.]*)"
    private static let ofPattern = "(\\d[\\d,.]*)\\s+(?:of|sur|von)\\s+(\\d[\\d,.]*)"

    public static func parse(_ title: String) -> PreviewPageInfo {
        // Take the last match: a filename may itself contain something like "2024/03".
        if let info = pageInfo(in: title, pattern: slashPattern) {
            return info
        }
        if let info = pageInfo(in: title, pattern: ofPattern) {
            return info
        }
        return .unknown
    }

    private static func pageInfo(in title: String, pattern: String) -> PreviewPageInfo? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(title.startIndex..<title.endIndex, in: title)
        guard let match = regex.matches(in: title, range: range).last,
              let pageRange = Range(match.range(at: 1), in: title),
              let countRange = Range(match.range(at: 2), in: title),
              let page = parseNumber(title[pageRange]),
              let count = parseNumber(title[countRange]),
              page >= 1, count >= 1, page <= count else {
            return nil
        }
        return PreviewPageInfo(page: page, pageCount: count)
    }

    private static func parseNumber(_ text: Substring) -> Int? {
        let digits = text.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
        return Int(digits)
    }
}

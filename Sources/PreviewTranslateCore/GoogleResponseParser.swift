import Foundation

/// Parses the translate_a/single response:
/// `[[["번역문","source sentence",...], ...], ...]`
public enum GoogleResponseParser {
    public enum ParseError: LocalizedError, Equatable {
        case htmlResponse
        case unexpectedShape

        public var errorDescription: String? {
            switch self {
            case .htmlResponse:
                return "번역 서버가 오류 페이지를 반환했습니다."
            case .unexpectedShape:
                return "번역 서버 응답을 해석하지 못했습니다."
            }
        }
    }

    public static func pairs(from data: Data) throws -> [TranslationPair] {
        guard !looksLikeHTML(data) else { throw ParseError.htmlResponse }
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let segments = root.first as? [Any] else {
            throw ParseError.unexpectedShape
        }

        var pairs: [TranslationPair] = []
        for segment in segments {
            guard let fields = segment as? [Any], fields.count >= 2,
                  let target = fields[0] as? String,
                  let source = fields[1] as? String else { continue }

            let trimmedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedTarget = target.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedSource.isEmpty && !trimmedTarget.isEmpty {
                pairs.append(TranslationPair(source: trimmedSource, target: trimmedTarget))
            }
        }

        guard !pairs.isEmpty else { throw ParseError.unexpectedShape }
        return pairs
    }

    static func looksLikeHTML(_ data: Data) -> Bool {
        let prefix = data.prefix(64)
        guard let text = String(data: prefix, encoding: .utf8) else { return false }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<")
    }
}

import Foundation

/// One aligned sentence: the original English and its Korean rendering.
public struct TranslationPair: Equatable, Sendable {
    public let source: String
    public let target: String

    public init(source: String, target: String) {
        self.source = source
        self.target = target
    }
}

/// The result of translating a page, plus which engine produced it.
public struct TranslationOutcome: Sendable {
    public let pairs: [TranslationPair]
    public let engineName: String

    public init(pairs: [TranslationPair], engineName: String) {
        self.pairs = pairs
        self.engineName = engineName
    }

    public var plainTarget: String {
        pairs.map(\.target).joined(separator: "\n\n")
    }

    public var bilingualText: String {
        pairs.map { "\($0.source)\n\($0.target)" }.joined(separator: "\n\n")
    }
}

public enum TranslationError: LocalizedError {
    case noTextOnPage
    case pageOutOfRange
    case onDeviceUnsupportedHardware
    case allEnginesFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noTextOnPage:
            return "이 페이지에 번역할 텍스트가 없습니다.\n스캔한 이미지 PDF는 지원하지 않습니다."
        case .pageOutOfRange:
            return "페이지 번호가 문서 범위를 벗어났습니다."
        case .onDeviceUnsupportedHardware:
            return "이 Mac에서는 Apple 온디바이스 번역을 사용할 수 없습니다.\nApple 온디바이스 번역은 Apple 실리콘(M1 이상) Mac에서만 동작합니다."
        case .allEnginesFailed(let detail):
            return "번역에 실패했습니다.\n\(detail)"
        }
    }

    /// The detail without the generic "번역에 실패했습니다." prefix, for callers that
    /// combine several failures into one message of their own.
    public var underlyingDetail: String? {
        if case .allEnginesFailed(let detail) = self { return detail }
        return nil
    }
}

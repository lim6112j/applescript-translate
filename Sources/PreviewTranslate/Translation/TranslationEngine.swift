import Foundation
import PreviewTranslateCore

enum TranslationSourceLanguage: String {
    case english = "en"
    case auto = "auto"

    var googleCode: String { rawValue }
}

protocol TranslationEngine: Sendable {
    var displayName: String { get }
    var isAvailable: Bool { get async }
    func translate(_ chunks: [String], from source: TranslationSourceLanguage) async throws -> [TranslationPair]
}

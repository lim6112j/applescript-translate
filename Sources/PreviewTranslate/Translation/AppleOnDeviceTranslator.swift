import Foundation
import Translation
import PreviewTranslateCore

/// Apple's on-device model: private and offline, but roughly 90 characters per
/// second on this Mac, so it is only used for a bounded amount of text.
actor AppleOnDeviceTranslator: TranslationEngine {
    nonisolated var displayName: String { "Apple 온디바이스 번역" }

    private let source = Locale.Language(identifier: "en")
    private let target = Locale.Language(identifier: "ko")

    private var session: TranslationSession?

    var isAvailable: Bool {
        get async {
            await LanguageAvailability().status(from: source, to: target) == .installed
        }
    }

    func translate(_ chunks: [String], from sourceLanguage: TranslationSourceLanguage) async throws -> [TranslationPair] {
        guard !chunks.isEmpty else { return [] }

        let prepared = try await preparedSession()

        var pairs: [TranslationPair] = []
        for chunk in chunks {
            try Task.checkCancellation()
            let response = try await prepared.translate(chunk)
            pairs.append(contentsOf: splitAligned(response.targetText, sourceChunk: chunk))
        }
        return pairs
    }

    func translate(_ text: String) async throws -> String {
        try await preparedSession().translate(text).targetText
    }

    /// Preparing also succeeds when `LanguageAvailability` reports the pair as merely
    /// `supported` (it wakes the asset service), so it is the reliable readiness check.
    func prepare() async throws {
        _ = try await preparedSession()
    }

    private func preparedSession() async throws -> TranslationSession {
        if let session { return session }

        let newSession = TranslationSession(installedSource: source, target: target)
        try await newSession.prepareTranslation()
        session = newSession
        return newSession
    }

    /// On-device translation returns one block; split it again so the viewer can
    /// still show source/translation side by side.
    private func splitAligned(_ translated: String, sourceChunk: String) -> [TranslationPair] {
        let targetSentences = SentenceSplitter.split(translated)
        let sourceSentences = SentenceSplitter.split(sourceChunk)

        guard targetSentences.count == sourceSentences.count else {
            return [TranslationPair(source: sourceChunk, target: translated)]
        }
        return zip(sourceSentences, targetSentences).map {
            TranslationPair(source: $0.0, target: $0.1)
        }
    }
}

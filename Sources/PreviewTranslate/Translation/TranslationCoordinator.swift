import Foundation
import PreviewTranslateCore

/// Runs the preferred engine first and falls back to the on-device engine, so a
/// missing network connection degrades speed instead of breaking translation.
actor TranslationCoordinator {
    private let google: TranslationEngine
    private let apple: AppleOnDeviceTranslator

    /// `PREVIEWTRANSLATE_ENGINE=apple` forces the on-device engine, which is handy
    /// for checking the fallback path without unplugging the network.
    private let forceOnDevice: Bool

    /// On-device runs at ~90 chars/s; cap what a single press can start.
    private let appleCharacterBudget = 2_500

    init(
        google: TranslationEngine = GoogleWebTranslator(),
        apple: AppleOnDeviceTranslator = AppleOnDeviceTranslator(),
        forceOnDevice: Bool = ProcessInfo.processInfo.environment["PREVIEWTRANSLATE_ENGINE"] == "apple"
    ) {
        self.google = google
        self.apple = apple
        self.forceOnDevice = forceOnDevice
    }

    func translate(blocks: [String], source: TranslationSourceLanguage) async throws -> TranslationOutcome {
        guard !blocks.isEmpty else { throw TranslationError.noTextOnPage }

        if !forceOnDevice, await GoogleWebTranslator.reachability.isReachable, await google.isAvailable {
            do {
                let pairs = try await google.translate(blocks, from: source)
                await GoogleWebTranslator.reachability.recordSuccess()
                return TranslationOutcome(pairs: pairs, engineName: google.displayName)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                await GoogleWebTranslator.reachability.recordFailure()
            }
        }

        do {
            try await apple.prepare()
        } catch {
            throw TranslationError.allEnginesFailed("Google 번역에 연결할 수 없고, 한국어 온디바이스 번역 언어팩도 사용할 수 없습니다.")
        }

        let limited = CharacterBudget.fit(blocks, to: appleCharacterBudget)
        let pairs = try await apple.translate(limited, from: source)
        return TranslationOutcome(pairs: pairs, engineName: apple.displayName)
    }
}

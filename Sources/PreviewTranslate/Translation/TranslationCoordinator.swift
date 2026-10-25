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

    /// Why the last Google attempt failed. Kept because `ReachabilityFlag` suppresses
    /// Google for 60s after a failure — without this, the next press would skip Google
    /// and report only that no fallback exists, hiding the actual cause.
    private var lastGoogleFailure: Error?

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
                lastGoogleFailure = nil
                return TranslationOutcome(pairs: pairs, engineName: google.displayName)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // A 429 proves the host answered, so it must not mark Google unreachable:
                // that would skip Google entirely on the next press and hide the cause.
                if !GoogleWebTranslator.isRateLimited(error) {
                    await GoogleWebTranslator.reachability.recordFailure()
                }
                lastGoogleFailure = error
            }
        }

        let onDeviceAvailable = AppleOnDeviceTranslator.isHardwareSupported
        var onDeviceFailure: String?

        if onDeviceAvailable {
            do {
                try await apple.prepare()
            } catch {
                onDeviceFailure = error.localizedDescription
            }
        }

        if onDeviceAvailable, onDeviceFailure == nil {
            let limited = CharacterBudget.fit(blocks, to: appleCharacterBudget)
            let pairs = try await apple.translate(limited, from: source)
            return TranslationOutcome(pairs: pairs, engineName: apple.displayName)
        }

        // Google is the only usable engine here, so its failure is the real reason —
        // never let the missing fallback take its place in the message.
        let primary = (lastGoogleFailure as? TranslationError)?.underlyingDetail
            ?? lastGoogleFailure?.localizedDescription
            ?? "Google 번역을 사용할 수 없습니다."
        throw TranslationError.allEnginesFailed(
            EngineDiagnosis.exhaustionDetail(
                primaryFailure: primary,
                onDeviceAvailable: onDeviceAvailable,
                onDeviceFailure: onDeviceFailure
            )
        )
    }
}

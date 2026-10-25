import Foundation

/// Builds the message shown when no engine could translate a page.
///
/// The primary failure is what actually went wrong (Google refused the request, timed
/// out, is unreachable). The hardware limit only explains why there was no fallback, so
/// it must never replace the cause — reporting a rate limit as "this Mac cannot do
/// on-device translation" sends the reader after the wrong problem.
public enum EngineDiagnosis {
    /// Whether a Google failure was a rate limit. A 429 means the host answered and is
    /// reachable, so it needs a longer retry and must not mark the engine unreachable.
    public static func isRateLimited(_ error: Error) -> Bool {
        guard let translation = error as? TranslationError else { return false }
        return translation.underlyingDetail?.contains("HTTP 429") ?? false
    }

    public static func exhaustionDetail(
        primaryFailure: String,
        onDeviceAvailable: Bool = false,
        onDeviceFailure: String? = nil
    ) -> String {
        var lines = [primaryFailure]

        if onDeviceAvailable {
            if let onDeviceFailure {
                lines.append("온디바이스 번역으로도 실패했습니다.\n\(onDeviceFailure)")
            }
        } else {
            lines.append("대체 엔진(Apple 온디바이스 번역)은 Apple 실리콘(M1 이상) Mac에서만 동작해 사용할 수 없습니다.")
        }

        return lines.joined(separator: "\n\n")
    }
}

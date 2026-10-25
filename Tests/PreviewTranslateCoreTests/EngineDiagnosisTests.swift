import XCTest
@testable import PreviewTranslateCore

final class EngineDiagnosisTests: XCTestCase {
    func testGoogleFailureLeadsTheMessage() {
        let googleError = "번역에 실패했습니다.\nGoogle 번역이 HTTP 429을 반환했습니다."
        let detail = EngineDiagnosis.exhaustionDetail(primaryFailure: googleError)

        XCTAssertTrue(
            detail.hasPrefix(googleError),
            "실제 원인(Google 오류)이 먼저 나와야 합니다. 실제: \(detail)"
        )
    }

    func testHardwareLimitIsExplainedAsContextNotAsTheCause() {
        let detail = EngineDiagnosis.exhaustionDetail(primaryFailure: "Google 번역이 HTTP 429을 반환했습니다.")

        XCTAssertTrue(detail.contains("Apple 실리콘"), "대체 엔진을 쓸 수 없는 이유를 밝혀야 합니다.")
        XCTAssertTrue(
            detail.contains("Google"),
            "원인과 대체 엔진 부재가 함께 설명되어야 합니다. 실제: \(detail)"
        )
    }

    func testExhaustionDetailNeverDropsThePrimaryFailure() {
        let detail = EngineDiagnosis.exhaustionDetail(primaryFailure: "연결 시간 초과")
        XCTAssertTrue(detail.contains("연결 시간 초과"), "원인을 하드웨어 문제로 덮어쓰면 안 됩니다.")
    }

    /// The exact message rendered when Google returns HTTP 429 with no fallback available:
    /// the rate limit must lead, because that is the actionable fact.
    func testRateLimitedMessageLeadsWithTheRateLimit() {
        let googleFailure: Error = TranslationError.allEnginesFailed("Google 번역이 HTTP 429을 반환했습니다.")
        let primary = (googleFailure as? TranslationError)?.underlyingDetail
            ?? googleFailure.localizedDescription

        let message = TranslationError.allEnginesFailed(
            EngineDiagnosis.exhaustionDetail(primaryFailure: primary, onDeviceAvailable: false)
        ).localizedDescription

        XCTAssertTrue(message.contains("429"), "실제 원인이 보여야 합니다. 실제: \(message)")
        XCTAssertTrue(message.contains("Apple 실리콘"), "대체 엔진이 없는 이유도 함께 설명해야 합니다.")
        XCTAssertFalse(
            message.hasPrefix("번역에 실패했습니다.\n이 Mac에서는"),
            "하드웨어 문구로 시작하면 원인을 잘못 짚게 됩니다. 실제: \(message)"
        )
    }

    func testUnderlyingDetailStripsTheGenericPrefix() {
        XCTAssertEqual(
            TranslationError.allEnginesFailed("원인").underlyingDetail,
            "원인",
            "이미 '번역에 실패했습니다.'가 붙은 문구를 다시 감싸면 중복됩니다."
        )
    }

    // MARK: - Rate-limit classification

    func testDetectsRateLimitFromHTTP429() {
        let error = TranslationError.allEnginesFailed("Google 번역이 HTTP 429을 반환했습니다.")
        XCTAssertTrue(EngineDiagnosis.isRateLimited(error))
    }

    func testOtherHTTPFailuresAreNotRateLimits() {
        for code in [500, 503, 404] {
            let error = TranslationError.allEnginesFailed("Google 번역이 HTTP \(code)을 반환했습니다.")
            XCTAssertFalse(EngineDiagnosis.isRateLimited(error), "HTTP \(code)은 속도 제한이 아닙니다.")
        }
    }

    func testConnectionErrorsAreNotRateLimits() {
        struct NetworkDown: Error {}
        XCTAssertFalse(EngineDiagnosis.isRateLimited(NetworkDown()))
        XCTAssertFalse(EngineDiagnosis.isRateLimited(TranslationError.noTextOnPage))
    }
}

import XCTest
@testable import PreviewTranslateCore

final class TranslationErrorTests: XCTestCase {
    func testUnsupportedHardwareErrorNamesTheRequirement() {
        let message = TranslationError.onDeviceUnsupportedHardware.errorDescription
        XCTAssertNotNil(message)
        XCTAssertTrue(message!.contains("Apple 실리콘"), "사용자가 원인을 알 수 있어야 합니다: \(message!)")
    }

    func testUnsupportedHardwareErrorIsNotWrappedAsAllEnginesFailed() {
        // The Intel case must stay distinguishable from a generic engine failure so the
        // panel can explain the hardware limit instead of blaming the network.
        let hardware: TranslationError = .onDeviceUnsupportedHardware
        let network: TranslationError = .allEnginesFailed("detail")

        XCTAssertNotEqual(hardware.errorDescription, network.errorDescription)
    }

    func testAllEnginesFailedStillIncludesItsDetail() {
        let message = TranslationError.allEnginesFailed("연결 실패").errorDescription
        XCTAssertTrue(message!.contains("연결 실패"))
    }
}

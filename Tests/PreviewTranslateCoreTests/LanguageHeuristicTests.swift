import XCTest
@testable import PreviewTranslateCore

final class LanguageHeuristicTests: XCTestCase {
    func testDetectsKoreanPage() {
        let text = "강화 학습은 오늘날 머신러닝의 가장 흥미진진한 분야 중 하나이자 가장 오래된 분야 중 하나입니다."
        XCTAssertTrue(LanguageHeuristic.isPredominantlyHangul(text))
    }

    func testTreatsEnglishPageAsNotKorean() {
        let text = "Reinforcement learning is one of the most exciting fields of machine learning today."
        XCTAssertFalse(LanguageHeuristic.isPredominantlyHangul(text))
    }

    func testIgnoresASingleKoreanWordInEnglishText() {
        let text = "Reinforcement learning is exciting and it has been around for a long time, 강화 학습."
        XCTAssertFalse(LanguageHeuristic.isPredominantlyHangul(text))
    }

    func testVeryShortTextIsNotJudged() {
        XCTAssertFalse(LanguageHeuristic.isPredominantlyHangul("강화 학습"))
    }
}

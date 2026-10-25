import Foundation
import PDFKit
import PreviewTranslateCore

struct PageRequest: Equatable {
    let documentURL: URL
    let pageIndex: Int
    let pageCount: Int
    let sourceLanguage: TranslationSourceLanguage
}

struct TranslationService {
    private let coordinator: TranslationCoordinator

    init(coordinator: TranslationCoordinator = TranslationCoordinator()) {
        self.coordinator = coordinator
    }

    /// Translates the page on a dedicated serial queue so PDFKit (which is not
    /// documented as thread-safe) is only ever touched from one place.
    func translatePage(_ request: PageRequest) async throws -> TranslationOutcome {
        let blocks: [String] = try await withCheckedThrowingContinuation { continuation in
            PageQueue.shared.async {
                do {
                    continuation.resume(returning: try Self.pageBlocks(at: request))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        guard !blocks.isEmpty else { throw TranslationError.noTextOnPage }

        let documentText = blocks.joined(separator: " ")
        if LanguageHeuristic.isPredominantlyHangul(documentText) {
            return TranslationOutcome(pairs: [], engineName: "")
        }

        return try await coordinator.translate(blocks: blocks, source: request.sourceLanguage)
    }

    private static func pageBlocks(at request: PageRequest) throws -> [String] {
        guard let document = PDFDocumentCache.shared.document(at: request.documentURL) else {
            throw TranslationError.allEnginesFailed("PDF 문서를 열 수 없습니다.")
        }
        guard request.pageIndex >= 0, request.pageIndex < document.pageCount else {
            throw TranslationError.pageOutOfRange
        }
        guard let page = document.page(at: request.pageIndex) else {
            throw TranslationError.pageOutOfRange
        }

        let lines = PDFPageTextExtractor.lines(from: page)
        return PageBlockBuilder.blocks(from: lines)
    }
}

private enum PageQueue {
    static let shared = PageQueueBox()
}

private final class PageQueueBox {
    private let queue = DispatchQueue(label: "dev.nixos.previewtranslate.pdf", qos: .userInitiated)

    func async(_ work: @escaping () -> Void) {
        queue.async(execute: work)
    }
}

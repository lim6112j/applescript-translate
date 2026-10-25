import Foundation
import PDFKit

/// Keeps the currently open PDF in memory so paging stays instant.
final class PDFDocumentCache {
    static let shared = PDFDocumentCache()

    private let lock = NSLock()
    private var cachedURL: URL?
    private var cachedDocument: PDFDocument?

    func document(at url: URL) -> PDFDocument? {
        lock.lock()
        defer { lock.unlock() }

        if cachedURL == url, let cachedDocument {
            return cachedDocument
        }
        guard let document = PDFDocument(url: url) else { return nil }
        cachedURL = url
        cachedDocument = document
        return document
    }
}

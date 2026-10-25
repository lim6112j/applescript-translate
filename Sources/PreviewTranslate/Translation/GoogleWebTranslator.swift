import Foundation
import PreviewTranslateCore

/// Uses the endpoint the Google Translate web page itself calls. It is fast (~1s per
/// page) but unofficial, so callers must keep a fallback engine around.
struct GoogleWebTranslator: TranslationEngine {
    static let endpoint = "https://translate.google.com/translate_a/single"

    private static let maxConcurrentRequests = 4
    private static let maxAttempts = 3
    private static let requestTimeout: TimeInterval = 8
    private static let baseRetryDelay: TimeInterval = 0.3
    private static let headingLengthLimit = 60

    /// Short and distinctive, so it is not throttled by the human-facing request limits.
    private static let userAgent = "PreviewTranslate/1.0"

    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            // The system PAC proxy stalls this host on some networks; the endpoint
            // is reachable directly.
            configuration.connectionProxyDictionary = [:]
            configuration.httpMaximumConnectionsPerHost = Self.maxConcurrentRequests
            configuration.timeoutIntervalForRequest = Self.requestTimeout
            configuration.waitsForConnectivity = false
            self.session = URLSession(configuration: configuration)
        }
    }

    var displayName: String { "Google 번역" }

    var isAvailable: Bool {
        get async { GoogleWebTranslator.reachability.isReachable }
    }

    func translate(_ chunks: [String], from source: TranslationSourceLanguage) async throws -> [TranslationPair] {
        guard !chunks.isEmpty else { return [] }

        // Blocks shorter than a sentence are usually headings, which read better as
        // their own row and cost nothing extra to translate separately.
        let groups = chunks.map { $0.count <= Self.headingLengthLimit ? [$0] : TextChunker.chunks(of: $0) }
            .flatMap { LetterGrouping.coalesce($0) }
        guard !groups.isEmpty else { return [] }

        let limit = min(Self.maxConcurrentRequests, groups.count)
        let indexedPairs = try await withThrowingTaskGroup(of: (Int, [TranslationPair]).self) { group in
            var nextIndex = 0
            var results: [(Int, [TranslationPair])] = []

            func enqueue(_ index: Int) {
                let chunk = groups[index]
                group.addTask {
                    let pairs = try await self.translateChunk(chunk, from: source)
                    return (index, pairs)
                }
            }

            while nextIndex < limit {
                enqueue(nextIndex)
                nextIndex += 1
            }

            while let result = try await group.next() {
                results.append(result)
                if nextIndex < groups.count {
                    enqueue(nextIndex)
                    nextIndex += 1
                }
            }
            return results
        }

        return indexedPairs.sorted { $0.0 < $1.0 }.flatMap(\.1)
    }

    // MARK: - Request

    private func translateChunk(_ chunk: String, from source: TranslationSourceLanguage) async throws -> [TranslationPair] {
        var lastError: Error = TranslationError.allEnginesFailed("Google 번역 요청이 실패했습니다.")

        for attempt in 0..<Self.maxAttempts {
            try Task.checkCancellation()
            do {
                return try await requestOnce(chunk, from: source)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
                if attempt < Self.maxAttempts - 1 {
                    let delay = Self.baseRetryDelay * Double(attempt + 1)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        throw lastError
    }

    private func requestOnce(_ chunk: String, from source: TranslationSourceLanguage) async throws -> [TranslationPair] {
        var components = URLComponents(string: Self.endpoint)!
        components.queryItems = [
            .init(name: "client", value: "gtx"),
            .init(name: "sl", value: source.googleCode),
            .init(name: "tl", value: "ko"),
            .init(name: "dt", value: "t"),
            .init(name: "q", value: chunk),
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = Self.requestTimeout
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TranslationError.allEnginesFailed("Google 번역 응답이 올바르지 않습니다.")
        }
        guard http.statusCode == 200 else {
            throw TranslationError.allEnginesFailed("Google 번역이 HTTP \(http.statusCode)을 반환했습니다.")
        }
        return try GoogleResponseParser.pairs(from: data)
    }
}

/// Tracks whether Google has recently failed, so the on-device engine can be used
/// directly instead of waiting for a timeout on every page.
final class ReachabilityFlag: @unchecked Sendable {
    static let shared = ReachabilityFlag()

    private let lock = NSLock()
    private var reachedAt: Date?
    private var failedAt: Date?
    private let retryInterval: TimeInterval = 60

    var isReachable: Bool {
        lock.lock()
        defer { lock.unlock() }
        if let failedAt {
            return Date().timeIntervalSince(failedAt) > retryInterval
        }
        return true
    }

    func recordSuccess() {
        lock.lock()
        failedAt = nil
        reachedAt = Date()
        lock.unlock()
    }

    func recordFailure() {
        lock.lock()
        failedAt = Date()
        lock.unlock()
    }
}

extension GoogleWebTranslator {
    static var reachability: ReachabilityFlag { .shared }
}

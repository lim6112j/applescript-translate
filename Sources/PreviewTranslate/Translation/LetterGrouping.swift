import Foundation
import PreviewTranslateCore

/// Sentence splitting is not available (and would be wrong) for every script, so
/// short leftover groups are folded into a neighbour to keep the request count low.
enum LetterGrouping {
    static let minimumCharacters = 20

    /// Merges every group shorter than `minimumCharacters` into the previous group.
    static func coalesce(_ groups: [String], minimumCharacters: Int = minimumCharacters) -> [String] {
        var merged: [String] = []

        for group in groups {
            let trimmed = group.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if trimmed.count < minimumCharacters, let last = merged.popLast() {
                merged.append(last + " " + trimmed)
            } else {
                merged.append(trimmed)
            }
        }

        return merged
    }
}

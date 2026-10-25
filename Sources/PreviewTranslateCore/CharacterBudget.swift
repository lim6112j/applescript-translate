import Foundation

/// Fits page content into a character budget, used for the slow on-device engine.
public enum CharacterBudget {
    /// Keeps whole paragraphs while they fit, then takes as many complete sentences of
    /// the next paragraph as the remaining budget allows.
    public static func fit(_ blocks: [String], to budget: Int) -> [String] {
        guard !blocks.isEmpty else { return [] }
        guard budget > 0 else { return [] }

        var result: [String] = []
        var used = 0

        for block in blocks {
            if used + block.count <= budget {
                result.append(block)
                used += block.count + 1
                continue
            }

            let remaining = budget - used
            if remaining > 0, let partial = sentencePrefix(of: block, maxCharacters: remaining) {
                result.append(partial)
            }
            break
        }

        if result.isEmpty {
            // A single paragraph longer than the budget: keep its first sentence(s).
            return sentencePrefix(of: blocks[0], maxCharacters: budget).map { [$0] } ?? []
        }
        return result
    }

    /// The longest prefix made of whole sentences that fits the limit, so the reader
    /// never sees a translation that stops mid-sentence.
    static func sentencePrefix(of text: String, maxCharacters: Int) -> String? {
        var prefix = ""
        for sentence in SentenceSplitter.split(text) {
            let candidate = prefix.isEmpty ? sentence : prefix + " " + sentence
            if candidate.count > maxCharacters { break }
            prefix = candidate
        }
        return prefix.isEmpty ? nil : prefix
    }
}

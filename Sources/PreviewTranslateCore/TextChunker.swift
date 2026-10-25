import Foundation

/// Groups sentences into request-sized chunks without cutting a sentence in half
/// (unless a single sentence is itself longer than the limit).
public enum TextChunker {
    public static let defaultMaxCharacters = 1500

    public static func chunks(of text: String, maxCharacters: Int = defaultMaxCharacters) -> [String] {
        guard maxCharacters > 0 else { return [text] }
        let sentences = SentenceSplitter.split(text)
        guard !sentences.isEmpty else { return [] }

        var chunks: [String] = []
        var current = ""

        for sentence in sentences {
            if sentence.count > maxCharacters {
                if !current.isEmpty {
                    chunks.append(current)
                    current = ""
                }
                chunks.append(contentsOf: hardSplit(sentence, maxCharacters: maxCharacters))
                continue
            }

            let candidate = current.isEmpty ? sentence : current + " " + sentence
            if candidate.count > maxCharacters {
                chunks.append(current)
                current = sentence
            } else {
                current = candidate
            }
        }

        if !current.isEmpty {
            chunks.append(current)
        }
        return chunks
    }

    /// Breaks an over-long sentence at word boundaries as close to the limit as possible.
    static func hardSplit(_ sentence: String, maxCharacters: Int) -> [String] {
        var parts: [String] = []
        var remainder = sentence

        while remainder.count > maxCharacters {
            let limitIndex = remainder.index(remainder.startIndex, offsetBy: maxCharacters)
            let window = remainder[..<limitIndex]
            let cutIndex = window.lastIndex(of: " ") ?? limitIndex
            let piece = remainder[..<cutIndex].trimmingCharacters(in: .whitespaces)
            if !piece.isEmpty {
                parts.append(piece)
            }
            remainder = String(remainder[cutIndex...]).trimmingCharacters(in: .whitespaces)
        }

        if !remainder.isEmpty {
            parts.append(remainder)
        }
        return parts
    }
}

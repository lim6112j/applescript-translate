import Foundation

public enum LanguageHeuristic {
    /// Lets us skip the translator when a page is already Korean, so we never show
    /// a "translation" that is identical to the source.
    public static func isPredominantlyHangul(_ text: String) -> Bool {
        var hangul = 0
        var letters = 0

        for scalar in text.unicodeScalars {
            if isHangul(scalar) {
                hangul += 1
                letters += 1
            } else if CharacterSet.letters.contains(scalar) {
                letters += 1
            }
        }

        // Require enough text that a stray Korean word cannot trigger the shortcut.
        guard letters >= 20 else { return false }
        return Double(hangul) / Double(letters) > 0.5
    }

    static func isHangul(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0xAC00...0xD7A3, // syllables
             0x1100...0x11FF, // jamo
             0x3130...0x318F: // compatibility jamo
            return true
        default:
            return false
        }
    }
}

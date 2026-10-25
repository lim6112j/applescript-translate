import AppKit

/// Writes without ever destroying what the user already had on the clipboard:
/// the previous contents are restored a few seconds later.
final class ClipboardWriter {
    static let shared = ClipboardWriter()

    private let pasteboard = NSPasteboard.general
    private var pendingRestore: DispatchWorkItem?

    func copy(_ text: String, restoreAfter delay: TimeInterval = 4) {
        pendingRestore?.cancel()

        let previous = pasteboard.pasteboardItems?.compactMap { $0.copy() as? NSPasteboardItem } ?? []
        let changeCountBeforeWrite = pasteboard.changeCount

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        let restore = DispatchWorkItem { [weak self] in
            guard let self else { return }
            // Restore only if nothing else has written to the pasteboard since.
            guard self.pasteboard.changeCount == changeCountBeforeWrite + 1 else { return }
            self.pasteboard.clearContents()
            if !previous.isEmpty {
                self.pasteboard.writeObjects(previous)
            }
        }
        pendingRestore = restore
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: restore)
    }
}

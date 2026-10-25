import AppKit
import ApplicationServices
import PreviewTranslateCore

enum PreviewAccessError: LocalizedError {
    case previewNotRunning
    case noOpenDocument
    case noAccessibilityPermission
    case cannotReadDocument

    var errorDescription: String? {
        switch self {
        case .previewNotRunning:
            return "미리보기(Preview)가 실행 중이 아닙니다."
        case .noOpenDocument:
            return "미리보기에 열린 PDF 문서가 없습니다."
        case .noAccessibilityPermission:
            return "미리보기를 제어하려면 손쉬운 사용 권한이 필요합니다.\n시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 PreviewTranslate를 허용해 주세요."
        case .cannotReadDocument:
            return "현재 문서의 경로를 읽을 수 없습니다."
        }
    }
}

struct PreviewDocument {
    let url: URL
    let windowTitle: String
    let page: Int?
    let pageCount: Int?

    var fileName: String { url.lastPathComponent }

    var pageLabel: String {
        guard let page else { return "" }
        if let pageCount { return "\(page)/\(pageCount)페이지" }
        return "\(page)페이지"
    }
}

enum PreviewAccess {
    static let bundleIdentifier = "com.apple.Preview"

    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// `AXIsProcessTrustedWithOptions(prompt: true)` shows a system prompt on every
    /// call while the app is untrusted, which makes macOS nag on each hotkey press.
    /// Register the app in the Accessibility list once per launch instead, and let
    /// the in-app alert point at System Settings on later attempts.
    private static var didRequestPermission = false

    static func requestAccessibilityPermission() {
        guard !didRequestPermission else { return }
        didRequestPermission = true
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Reads the frontmost Preview window: its document path and the page it shows.
    static func currentDocument() throws -> PreviewDocument {
        guard let application = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == bundleIdentifier
        }) else {
            throw PreviewAccessError.previewNotRunning
        }

        guard isAccessibilityTrusted else {
            throw PreviewAccessError.noAccessibilityPermission
        }

        let appElement = AXUIElementCreateApplication(application.processIdentifier)

        guard let windows = attribute(appElement, kAXWindowsAttribute) as? [AXUIElement] else {
            throw PreviewAccessError.noOpenDocument
        }

        // Preview numbers document windows with AXIdentifier "PVDocumentWindow".
        let documentWindows = windows.filter { window in
            (attribute(window, "AXIdentifier") as? String) == "PVDocumentWindow"
        }
        guard let window = documentWindows.first ?? windows.first else {
            throw PreviewAccessError.noOpenDocument
        }

        guard let path = attribute(window, "AXDocument") as? String,
              let url = documentURL(from: path) else {
            throw PreviewAccessError.cannotReadDocument
        }

        let title = attribute(window, kAXTitleAttribute) as? String ?? ""
        let info = PreviewTitleParser.parse(title)

        return PreviewDocument(url: url, windowTitle: title, page: info.page, pageCount: info.pageCount)
    }

    private static func attribute(_ element: AXUIElement, _ name: String) -> AnyObject? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    private static func documentURL(from rawPath: String) -> URL? {
        if let url = URL(string: rawPath), url.isFileURL {
            return url
        }
        let expanded = (rawPath as NSString).expandingTildeInPath
        return FileManager.default.fileExists(atPath: expanded) ? URL(fileURLWithPath: expanded) : nil
    }
}

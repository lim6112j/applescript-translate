import AppKit
import PreviewTranslateCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var panel: TranslationPanel?
    private var hotkey: HotkeyManager?
    private let service = TranslationService()
    private var currentTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setUpPanel()
        setUpHotkey()
        setUpStatusItem()

        if !PreviewAccess.isAccessibilityTrusted {
            // Do not fire the system prompt on every launch: only register the app
            // in the Accessibility list, then explain what to do in-app.
            PreviewAccess.requestAccessibilityPermission()
            presentAccessibilityNotice()
        }
        if let panel, !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        currentTask?.cancel()
        hotkey?.unregister()
    }

    // MARK: - Setup

    private func setUpPanel() {
        let panel = TranslationPanel()
        panel.delegate = self
        panel.placeBesidePreview()
        panel.orderFrontRegardless()
        self.panel = panel
    }

    private func setUpHotkey() {
        let hotkey = HotkeyManager { [weak self] in
            self?.translateCurrentPage()
        }
        hotkey.register()
        self.hotkey = hotkey
    }

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: "character.book.closed",
            accessibilityDescription: "PreviewTranslate"
        )

        let menu = NSMenu()
        menu.addItem(withTitle: "현재 페이지 번역  ⌥⌘T", action: #selector(translateCurrentPage), keyEquivalent: "").target = self
        menu.addItem(withTitle: "번역 창 보기", action: #selector(showPanel), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "손쉬운 사용 권한 열기", action: #selector(openAccessibilitySettings), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "PreviewTranslate 종료", action: #selector(quit), keyEquivalent: "q").target = self
        item.menu = menu
        statusItem = item
    }

    // MARK: - Translation

    @objc func translateCurrentPage() {
        let document: PreviewDocument
        do {
            document = try PreviewAccess.currentDocument()
        } catch {
            showError(error.localizedDescription)
            return
        }

        guard let page = document.page else {
            showError("미리보기 창에서 현재 페이지 번호를 읽을 수 없습니다.\nPDF 문서 창이 활성 상태인지 확인해 주세요.")
            return
        }

        currentTask?.cancel()
        let request = PageRequest(
            documentURL: document.url,
            pageIndex: page - 1,
            pageCount: document.pageCount ?? 0,
            sourceLanguage: .english
        )

        // Reopen the panel if the reader closed it earlier.
        panel?.placeBesidePreview()
        panel?.orderFrontRegardless()
        panel?.showLoading(documentLabel: document.fileName, pageLabel: document.pageLabel)

        currentTask = Task { [service] in
            do {
                let outcome = try await service.translatePage(request)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.panel?.showResult(outcome, documentLabel: document.fileName, pageLabel: document.pageLabel)
                }
            } catch is CancellationError {
                // Superseded by a newer request.
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.panel?.showError(error.localizedDescription)
                }
            }
        }
    }

    private func showError(_ message: String) {
        panel?.placeBesidePreview()
        panel?.orderFrontRegardless()
        panel?.showError(message)
    }

    // MARK: - Menu actions

    @objc private func showPanel() {
        panel?.placeBesidePreview()
        panel?.orderFrontRegardless()
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        (notification.object as? TranslationPanel)?.rememberFrame()
    }

    private func presentAccessibilityNotice() {
        let alert = NSAlert()
        alert.messageText = "손쉬운 사용 권한이 필요합니다"
        alert.informativeText = "미리보기에서 현재 페이지를 읽으려면 권한이 필요합니다.\n시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 PreviewTranslate를 켜 주세요.\n\n권한을 켠 뒤에는 앱을 다시 실행해야 적용됩니다."
        alert.addButton(withTitle: "권한 설정 열기")
        alert.addButton(withTitle: "나중에")
        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }
}

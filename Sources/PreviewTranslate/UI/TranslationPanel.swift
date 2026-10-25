import AppKit
import PreviewTranslateCore

/// Always-on-top window that mirrors the page being read in Preview.
final class TranslationPanel: NSPanel {
    private let headerLabel = ParagraphPairView.makeLabel(size: 12, isSecondary: true, weight: .semibold)
    private let engineLabel = ParagraphPairView.makeLabel(size: 10, isSecondary: true, weight: .regular)
    private let contentStack = NSStackView()
    private let scrollView = NSScrollView()
    private let statusView = StatusView()
    private let modeControl = NSSegmentedControl(labels: ["한국어", "영어 + 한국어"], trackingMode: .selectOne, target: nil, action: nil)
    private let copyButton = NSButton(title: "복사", target: nil, action: nil)

    private var outcome: TranslationOutcome?

    static let defaultWidth: CGFloat = 430
    static let defaultHeight: CGFloat = 540

    /// The panel must not steal focus from Preview when the hotkey is pressed.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.defaultWidth, height: Self.defaultHeight),
            styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        title = "PreviewTranslate"
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        backgroundColor = .windowBackgroundColor

        buildLayout()
        showReady()
    }

    // MARK: - Layout

    private func buildLayout() {
        let contentView = NSView()
        self.contentView = contentView

        headerLabel.lineBreakMode = .byTruncatingMiddle
        modeControl.selectedSegment = 1
        modeControl.segmentStyle = .texturedRounded
        modeControl.target = self
        modeControl.action = #selector(modeChanged)

        copyButton.bezelStyle = .rounded
        copyButton.controlSize = .small
        copyButton.font = .systemFont(ofSize: 11)
        copyButton.target = self
        copyButton.action = #selector(copyTranslation)

        let headerRow = NSStackView(views: [headerLabel, spacer(), modeControl, copyButton])
        headerRow.orientation = .horizontal
        headerRow.alignment = .centerY
        headerRow.spacing = 8

        engineLabel.alignment = .right

        let separator = NSBox()
        separator.boxType = .separator

        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 16, right: 16)

        let documentView = FlippedView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(contentStack)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.documentView = documentView

        statusView.translatesAutoresizingMaskIntoConstraints = false

        let header = NSStackView(views: [headerRow, engineLabel, separator])
        header.orientation = .vertical
        header.alignment = .leading
        header.spacing = 6
        header.edgeInsets = NSEdgeInsets(top: 10, left: 16, bottom: 8, right: 16)
        header.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(header)
        contentView.addSubview(scrollView)
        contentView.addSubview(statusView)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: contentView.topAnchor),
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            headerRow.widthAnchor.constraint(equalTo: header.widthAnchor, constant: -32),
            engineLabel.widthAnchor.constraint(equalTo: headerRow.widthAnchor),
            separator.widthAnchor.constraint(equalTo: headerRow.widthAnchor),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            statusView.topAnchor.constraint(equalTo: header.bottomAnchor),
            statusView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            documentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            documentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),

            contentStack.topAnchor.constraint(equalTo: documentView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: documentView.bottomAnchor),
        ])
    }

    private func spacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    // MARK: - States

    func showReady(shortcut: String = "⌥⌘T") {
        outcome = nil
        headerLabel.stringValue = "PreviewTranslate"
        engineLabel.stringValue = ""
        statusView.isHidden = false
        scrollView.isHidden = true
        statusView.showReady(shortcut: shortcut)
        modeControl.isEnabled = false
        copyButton.isEnabled = false
    }

    func showLoading(documentLabel: String, pageLabel: String) {
        outcome = nil
        headerLabel.stringValue = pageLabel.isEmpty ? documentLabel : "\(documentLabel) · \(pageLabel)"
        engineLabel.stringValue = ""
        statusView.isHidden = false
        scrollView.isHidden = true
        statusView.showLoading(message: "번역하는 중…")
    }

    func showError(_ message: String) {
        outcome = nil
        statusView.isHidden = false
        scrollView.isHidden = true
        statusView.showError(message)
        modeControl.isEnabled = false
        copyButton.isEnabled = false
    }

    func showResult(_ outcome: TranslationOutcome, documentLabel: String, pageLabel: String) {
        self.outcome = outcome

        if outcome.pairs.isEmpty {
            // Page is already Korean: nothing to translate.
            headerLabel.stringValue = pageLabel.isEmpty ? documentLabel : "\(documentLabel) · \(pageLabel)"
            engineLabel.stringValue = ""
            statusView.isHidden = false
            scrollView.isHidden = true
            statusView.showMessage("이 페이지는 이미 한국어입니다.")
            modeControl.isEnabled = false
            copyButton.isEnabled = false
            return
        }

        headerLabel.stringValue = pageLabel.isEmpty ? documentLabel : "\(documentLabel) · \(pageLabel)"
        engineLabel.stringValue = outcome.engineName
        statusView.isHidden = true
        scrollView.isHidden = false
        modeControl.isEnabled = true
        copyButton.isEnabled = true
        render()
        scrollView.contentView.scroll(to: .zero)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func render() {
        guard let outcome else { return }
        let showSource = modeControl.selectedSegment == 1

        for view in contentStack.arrangedSubviews {
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for pair in outcome.pairs {
            let pairView: NSView
            if showSource {
                pairView = ParagraphPairView(pair: pair)
            } else {
                let label = ParagraphPairView.makeLabel(size: 15, isSecondary: false, weight: .regular)
                label.stringValue = pair.target
                pairView = label
            }
            contentStack.addArrangedSubview(pairView)
            pairView.widthAnchor.constraint(equalTo: contentStack.widthAnchor, constant: -32).isActive = true
        }
    }

    // MARK: - Actions

    @objc private func modeChanged() {
        render()
    }

    @objc private func copyTranslation() {
        guard let outcome else { return }
        let text = modeControl.selectedSegment == 1 ? outcome.bilingualText : outcome.plainTarget
        ClipboardWriter.shared.copy(text)
        copyButton.title = "복사됨"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copyButton.title = "복사"
        }
    }

    // MARK: - Placement

    /// Puts the panel beside Preview's front window instead of on top of the text.
    func placeBesidePreview() {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame

        // Respect a position the reader chose themselves.
        if let savedFrame = savedFrame(), visible.intersects(savedFrame) {
            setFrame(savedFrame.clampedTo(visible), display: true)
            return
        }

        let targetFrame: NSRect
        if let previewFrame = frontmostPreviewWindowFrame(),
           previewFrame.maxX + 12 + Self.defaultWidth <= visible.maxX {
            targetFrame = NSRect(x: previewFrame.maxX + 12,
                                 y: previewFrame.maxY - Self.defaultHeight,
                                 width: Self.defaultWidth,
                                 height: Self.defaultHeight)
        } else if let previewFrame = frontmostPreviewWindowFrame(),
                  previewFrame.width > 900 {
            // Preview is full screen: sit over the page margin, clear of the text column.
            let x = min(visible.maxX - Self.defaultWidth - 4, previewFrame.maxX - Self.defaultWidth - 70)
            targetFrame = NSRect(x: x, y: previewFrame.maxY - Self.defaultHeight,
                                 width: Self.defaultWidth,
                                 height: Self.defaultHeight)
        } else {
            targetFrame = NSRect(x: visible.maxX - Self.defaultWidth - 8,
                                 y: visible.maxY - Self.defaultHeight - 8,
                                 width: Self.defaultWidth,
                                 height: Self.defaultHeight)
        }
        setFrame(targetFrame.clampedTo(visible), display: true)
    }

    private static let frameDefaultsKey = "TranslationPanelFrame"

    private func savedFrame() -> NSRect? {
        guard let raw = UserDefaults.standard.string(forKey: Self.frameDefaultsKey) else { return nil }
        let frame = NSRectFromString(raw)
        return frame.isEmpty ? nil : frame
    }

    /// Called on close so the next launch restores where the reader put the panel.
    func rememberFrame() {
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: Self.frameDefaultsKey)
    }

    private func frontmostPreviewWindowFrame() -> NSRect? {
        guard let application = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == PreviewAccess.bundleIdentifier
        }) else { return nil }

        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value) == .success,
              let windows = value as? [AXUIElement], let window = windows.first else { return nil }

        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success
        else { return nil }

        var origin = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionValue as! AXValue, .cgPoint, &origin)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)

        // Accessibility reports top-left origin coordinates; AppKit uses bottom-left.
        let screenHeight = NSScreen.screens.first?.frame.height ?? 0
        let flippedY = screenHeight - origin.y - size.height
        return NSRect(x: origin.x, y: flippedY, width: size.width, height: size.height)
    }
}

private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

private extension NSRect {
    func clampedTo(_ bounds: NSRect) -> NSRect {
        var result = self
        result.origin.x = max(bounds.minX, min(result.origin.x, bounds.maxX - result.width))
        result.origin.y = max(bounds.minY, min(result.origin.y, bounds.maxY - result.height))
        return result
    }
}

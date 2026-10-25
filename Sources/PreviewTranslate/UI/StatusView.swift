import AppKit

/// Centre panel used for "ready", "working" and error states.
final class StatusView: NSView {
    private let titleLabel = ParagraphPairView.makeLabel(size: 15, isSecondary: false, weight: .medium)
    private let detailLabel = ParagraphPairView.makeLabel(size: 12, isSecondary: true, weight: .regular)
    private let spinner = NSProgressIndicator()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.alignment = .center
        detailLabel.alignment = .center
        buildLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildLayout() {
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false
        spinner.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [spinner, titleLabel, detailLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
        ])
    }

    func showReady(shortcut: String) {
        spinner.stopAnimation(nil)
        titleLabel.stringValue = "미리보기에서 페이지를 연 뒤 번역하세요"
        detailLabel.stringValue = "\(shortcut) 를 누르면 현재 페이지 전체를 한국어로 번역합니다."
    }

    func showLoading(message: String) {
        spinner.startAnimation(nil)
        titleLabel.stringValue = message
        detailLabel.stringValue = ""
    }

    func showError(_ message: String) {
        spinner.stopAnimation(nil)
        titleLabel.stringValue = message
        detailLabel.stringValue = ""
    }

    func showMessage(_ title: String, detail: String = "") {
        spinner.stopAnimation(nil)
        titleLabel.stringValue = title
        detailLabel.stringValue = detail
    }
}

import AppKit
import PreviewTranslateCore

/// One sentence block: the English original above its Korean translation.
final class ParagraphPairView: NSView {
    private let sourceLabel = ParagraphPairView.makeLabel(size: 12, isSecondary: true, weight: .regular)
    private let targetLabel = ParagraphPairView.makeLabel(size: 15, isSecondary: false, weight: .regular)

    init(pair: TranslationPair) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        sourceLabel.stringValue = pair.source
        targetLabel.stringValue = pair.target
        buildLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildLayout() {
        let stack = NSStackView(views: [sourceLabel, targetLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    static func makeLabel(size: CGFloat, isSecondary: Bool, weight: NSFont.Weight) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: "")
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = isSecondary ? .secondaryLabelColor : .labelColor
        label.isSelectable = true
        label.maximumNumberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        return label
    }
}

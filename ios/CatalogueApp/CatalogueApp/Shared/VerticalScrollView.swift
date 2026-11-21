import UIKit

// A scroll view that stacks views from top to bottom. Add your views to `contentStack`.
final class VerticalScrollView: UIScrollView {
    let contentStack = UIStackView()

    init(spacing: CGFloat) {
        super.init(frame: .zero)
        alwaysBounceVertical = true
        keyboardDismissMode = .interactive

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = spacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        let margin = Theme.Spacing.medium
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: margin),
            contentStack.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor, constant: -margin),
            contentStack.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: margin),
            contentStack.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor, constant: -margin),
            // The content is as wide as the screen, so it only scrolls up and down.
            contentStack.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor, constant: -margin * 2)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }
}

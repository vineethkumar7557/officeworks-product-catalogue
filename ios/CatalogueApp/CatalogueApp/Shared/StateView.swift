import UIKit

// Shows a spinner, or a message with an optional "Try again" button.
// Screens put it on top of their content while loading, when empty, or after an error.
final class StateView: UIView {
    var onRetry: (() -> Void)?

    private let spinner = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    // Lets us write StateView() without a frame.
    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    func showLoading() {
        isHidden = false
        spinner.startAnimating()
        messageLabel.isHidden = true
        retryButton.isHidden = true
    }

    func showMessage(_ text: String, canRetry: Bool) {
        isHidden = false
        spinner.stopAnimating()
        messageLabel.text = text
        messageLabel.isHidden = false
        retryButton.isHidden = !canRetry
    }

    func hide() {
        isHidden = true
        spinner.stopAnimating()
    }

    private func setUp() {
        messageLabel.font = Theme.Font.body
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = Theme.Color.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Try again"
        retryButton.configuration = configuration
        retryButton.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [spinner, messageLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Theme.Spacing.medium
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Spacing.large),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Spacing.large),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

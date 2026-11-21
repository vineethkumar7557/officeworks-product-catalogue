import UIKit

// Shown after the enquiry was sent. It has no logic, so it has no view model.
final class ThankYouViewController: UIViewController {
    private let productTitle: String

    // The router sets this.
    var onDone: (() -> Void)?

    init(productTitle: String) {
        self.productTitle = productTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.background
        navigationItem.hidesBackButton = true

        let iconView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iconView.tintColor = Theme.Color.success
        iconView.contentMode = .scaleAspectFit
        iconView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = "Thank you!"
        titleLabel.font = Theme.Font.title
        titleLabel.textColor = Theme.Color.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .header

        let messageLabel = UILabel()
        messageLabel.text = "We have received your enquiry about \(productTitle). Our sales team will be in touch soon."
        messageLabel.font = Theme.Font.body
        messageLabel.textColor = Theme.Color.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.adjustsFontForContentSizeCategory = true

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Done"
        configuration.buttonSize = .large
        let doneButton = UIButton(type: .system)
        doneButton.configuration = configuration
        doneButton.addAction(UIAction { [weak self] _ in self?.onDone?() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, messageLabel, doneButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = Theme.Spacing.large
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.Spacing.large),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Theme.Spacing.large),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

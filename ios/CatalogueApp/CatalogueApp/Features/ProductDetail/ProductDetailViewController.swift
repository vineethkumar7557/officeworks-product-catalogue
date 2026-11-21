import UIKit

// The product details page, with the Enquire button fixed at the bottom.
final class ProductDetailViewController: UIViewController {
    private let viewModel: ProductDetailViewModel

    // The router sets this. The screen only reports the tap.
    var onEnquire: ((Product) -> Void)?

    init(viewModel: ProductDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Details"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Theme.Color.background

        let scrollView = makeContent()
        let bottomBar = makeBottomBar()

        view.addSubview(scrollView)
        view.addSubview(bottomBar)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Building the screen

    private func makeContent() -> VerticalScrollView {
        let scrollView = VerticalScrollView(spacing: Theme.Spacing.small)

        let imageView = RemoteImageView()
        imageView.layer.cornerRadius = Theme.Shape.cornerRadius
        imageView.clipsToBounds = true
        imageView.setImage(from: viewModel.imageURL)
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.9).isActive = true

        let categoryLabel = makeLabel(viewModel.categoryText.uppercased(), font: Theme.Font.caption, color: Theme.Color.textSecondary)
        let titleLabel = makeLabel(viewModel.title, font: Theme.Font.title, color: Theme.Color.textPrimary)
        let ratingLabel = makeLabel(viewModel.ratingText, font: Theme.Font.body, color: Theme.Color.star)
        let priceLabel = makeLabel(viewModel.priceText, font: Theme.Font.price, color: Theme.Color.textPrimary)
        let headingLabel = makeLabel("Description", font: Theme.Font.heading, color: Theme.Color.textPrimary)
        let descriptionLabel = makeLabel(viewModel.descriptionText, font: Theme.Font.body, color: Theme.Color.textSecondary)
        headingLabel.accessibilityTraits = .header

        scrollView.contentStack.addArrangedSubview(imageView)
        scrollView.contentStack.setCustomSpacing(Theme.Spacing.medium, after: imageView)
        scrollView.contentStack.addArrangedSubview(categoryLabel)
        scrollView.contentStack.addArrangedSubview(titleLabel)
        scrollView.contentStack.addArrangedSubview(ratingLabel)
        scrollView.contentStack.addArrangedSubview(priceLabel)
        scrollView.contentStack.setCustomSpacing(Theme.Spacing.large, after: priceLabel)
        scrollView.contentStack.addArrangedSubview(headingLabel)
        scrollView.contentStack.addArrangedSubview(descriptionLabel)
        return scrollView
    }

    private func makeBottomBar() -> UIView {
        let bar = UIView()
        bar.backgroundColor = Theme.Color.background

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Enquire"
        configuration.buttonSize = .large
        let button = UIButton(type: .system)
        button.configuration = configuration
        button.addAction(UIAction { [weak self] _ in self?.enquireTapped() }, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: bar.topAnchor, constant: Theme.Spacing.medium),
            button.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: Theme.Spacing.medium),
            button.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -Theme.Spacing.medium),
            button.bottomAnchor.constraint(equalTo: bar.safeAreaLayoutGuide.bottomAnchor, constant: -Theme.Spacing.medium)
        ])
        return bar
    }

    private func makeLabel(_ text: String, font: UIFont, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    private func enquireTapped() {
        onEnquire?(viewModel.product)
    }
}

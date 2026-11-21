import UIKit

// TEMPORARY screen so a tapped product opens something. Step 10 builds the real details page here.
final class ProductDetailViewController: UIViewController {
    private let product: Product

    init(product: Product) {
        self.product = product
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

        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Theme.Font.heading
        label.textColor = Theme.Color.textPrimary
        label.text = "\(product.title)\n\n\(product.priceText)"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

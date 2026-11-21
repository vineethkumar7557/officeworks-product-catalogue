import UIKit
import Foundation

// TEMPORARY screen that proves the app can reach the backend.
// Step 9 replaces it with the real Home screen.
final class HomeViewController: UIViewController {
    private let apiClient: APIClient
    private let statusLabel = UILabel()

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Catalogue"
        view.backgroundColor = Theme.Color.background

        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.font = Theme.Font.body
        statusLabel.textColor = Theme.Color.textPrimary
        statusLabel.text = "Loading…"
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        Task { await self.loadFeaturedProducts() }
    }

    private func loadFeaturedProducts() async {
        do {
            let products = try await apiClient.featuredProducts()
            let titles = products.map { $0.title }.joined(separator: "\n\n")
            statusLabel.text = "Backend OK: \(products.count) featured products\n\n\(titles)"
        } catch {
            statusLabel.text = error.localizedDescription
        }
    }
}

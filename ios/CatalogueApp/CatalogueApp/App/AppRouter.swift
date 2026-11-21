import UIKit

// Decides which screen opens next. Screens only report taps. They never create other screens.
@MainActor
final class AppRouter {
    private let navigationController: UINavigationController
    private let apiClient: APIClient

    init(navigationController: UINavigationController, apiClient: APIClient) {
        self.navigationController = navigationController
        self.apiClient = apiClient
    }

    func start() {
        navigationController.navigationBar.prefersLargeTitles = true

        let home = HomeViewController(viewModel: HomeViewModel(apiClient: apiClient))
        home.onProductSelected = { [weak self] product in self?.showProduct(product) }
        home.onCategorySelected = { [weak self] name in self?.showCategory(name) }
        home.onSearch = { [weak self] term in self?.showSearch(term) }
        navigationController.setViewControllers([home], animated: false)
    }

    private func showCategory(_ categoryName: String) {
        let viewModel = CategoryViewModel(categoryName: categoryName, apiClient: apiClient)
        let screen = CategoryViewController(viewModel: viewModel)
        screen.onProductSelected = { [weak self] product in self?.showProduct(product) }
        navigationController.pushViewController(screen, animated: true)
    }

    private func showSearch(_ term: String) {
        let viewModel = SearchViewModel(term: term, apiClient: apiClient)
        let screen = SearchViewController(viewModel: viewModel)
        screen.onProductSelected = { [weak self] product in self?.showProduct(product) }
        navigationController.pushViewController(screen, animated: true)
    }

    private func showProduct(_ product: Product) {
        let screen = ProductDetailViewController(viewModel: ProductDetailViewModel(product: product))
        screen.onEnquire = { [weak self] product in self?.showEnquiry(for: product) }
        navigationController.pushViewController(screen, animated: true)
    }

    // The enquiry form opens on top of the catalogue, in its own navigation controller.
    private func showEnquiry(for product: Product) {
        let viewModel = EnquiryViewModel(product: product, apiClient: apiClient)
        let form = EnquiryViewController(viewModel: viewModel)
        let enquiryNavigation = UINavigationController(rootViewController: form)

        form.onCancel = { [weak self] in
            self?.navigationController.dismiss(animated: true)
        }
        form.onSubmitted = { [weak self, weak enquiryNavigation] in
            guard let self, let enquiryNavigation else { return }
            self.showThankYou(for: product, in: enquiryNavigation)
        }
        navigationController.present(enquiryNavigation, animated: true)
    }

    private func showThankYou(for product: Product, in enquiryNavigation: UINavigationController) {
        let screen = ThankYouViewController(productTitle: product.title)
        screen.onDone = { [weak self] in
            self?.navigationController.dismiss(animated: true)
        }
        enquiryNavigation.pushViewController(screen, animated: true)
    }
}

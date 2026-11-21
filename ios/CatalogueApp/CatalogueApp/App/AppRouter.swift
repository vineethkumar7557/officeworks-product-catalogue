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
        let screen = ProductDetailViewController(product: product)
        navigationController.pushViewController(screen, animated: true)
    }
}

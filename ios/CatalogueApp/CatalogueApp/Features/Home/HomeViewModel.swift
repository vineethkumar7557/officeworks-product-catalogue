import Foundation

struct HomeContent: Equatable {
    let featuredProducts: [Product]
    let categories: [String]
}

// Loads what the Home screen shows. It knows nothing about UIKit.
@MainActor
final class HomeViewModel {
    private let apiClient: APIClient

    // The screen sets this to be told when the state changes.
    var onStateChange: ((ViewState<HomeContent>) -> Void)?

    private(set) var state: ViewState<HomeContent> = .loading {
        didSet { onStateChange?(state) }
    }

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        state = .loading
        do {
            let featuredProducts = try await apiClient.featuredProducts()
            let categories = try await apiClient.categories()
            if featuredProducts.isEmpty && categories.isEmpty {
                state = .empty
            } else {
                state = .loaded(HomeContent(featuredProducts: featuredProducts, categories: categories))
            }
        } catch is CancellationError {
            // The screen went away. There is nobody to tell.
            return
        } catch {
            state = .failed(error.customerMessage)
        }
    }
}

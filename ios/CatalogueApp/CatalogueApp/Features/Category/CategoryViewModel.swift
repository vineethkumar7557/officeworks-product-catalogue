import Foundation

// Loads one category page: the top rated products first, then the additional ones.
@MainActor
final class CategoryViewModel {
    let categoryName: String
    private let apiClient: APIClient

    var onStateChange: ((ViewState<CategoryProducts>) -> Void)?

    private(set) var state: ViewState<CategoryProducts> = .loading {
        didSet { onStateChange?(state) }
    }

    init(categoryName: String, apiClient: APIClient) {
        self.categoryName = categoryName
        self.apiClient = apiClient
    }

    var title: String {
        return categoryName.displayName
    }

    // The groups the screen shows, in order. A group with no products is left out.
    var sections: [ProductSection] {
        guard case .loaded(let result) = state else { return [] }
        var sections: [ProductSection] = []
        if !result.topRated.isEmpty {
            sections.append(ProductSection(title: "Top rated", products: result.topRated))
        }
        if !result.others.isEmpty {
            sections.append(ProductSection(title: "More products", products: result.others))
        }
        return sections
    }

    func load() async {
        state = .loading
        do {
            let result = try await apiClient.categoryProducts(categoryName: categoryName)
            if result.topRated.isEmpty && result.others.isEmpty {
                state = .empty
            } else {
                state = .loaded(result)
            }
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error.customerMessage)
        }
    }
}

import Foundation

enum SearchTerm {
    // Removes spaces around the typed text. Returns nil when nothing useful was typed.
    static func cleaned(_ text: String?) -> String? {
        let trimmed = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// Loads the products that match one search. The search starts only after the customer taps Search.
@MainActor
final class SearchViewModel {
    let term: String
    private let apiClient: APIClient

    var onStateChange: ((ViewState<[Product]>) -> Void)?

    private(set) var state: ViewState<[Product]> = .loading {
        didSet { onStateChange?(state) }
    }

    init(term: String, apiClient: APIClient) {
        self.term = term
        self.apiClient = apiClient
    }

    var emptyMessage: String {
        return "No products match “\(term)”. Try a different word."
    }

    // One group with a header like: 2 results for “jacket”.
    var sections: [ProductSection] {
        guard case .loaded(let products) = state else { return [] }
        let noun = (products.count == 1) ? "result" : "results"
        return [ProductSection(title: "\(products.count) \(noun) for “\(term)”", products: products)]
    }

    func load() async {
        state = .loading
        do {
            let products = try await apiClient.searchProducts(term: term)
            state = products.isEmpty ? .empty : .loaded(products)
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error.customerMessage)
        }
    }
}

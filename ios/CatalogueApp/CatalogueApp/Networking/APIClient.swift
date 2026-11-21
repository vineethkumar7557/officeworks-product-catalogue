import Foundation

// Everything the app asks from the backend. View models only know this protocol,
// so tests can give them a fake instead of the real network.
protocol APIClient {
    func featuredProducts() async throws -> [Product]
    func categories() async throws -> [String]
    func categoryProducts(categoryName: String) async throws -> CategoryProducts
    func searchProducts(term: String) async throws -> [Product]
    func product(id: Int) async throws -> Product
    func submitEnquiry(_ enquiry: Enquiry) async throws
}

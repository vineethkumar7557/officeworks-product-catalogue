import Foundation
@testable import CatalogueApp

// A pretend backend for view model tests. A test sets the answer it wants, then checks what was asked.
final class MockAPIClient: APIClient {
    var featuredResult: Result<[Product], Error> = .success([])
    var categoriesResult: Result<[String], Error> = .success([])
    var categoryProductsResult: Result<CategoryProducts, Error> = .success(
        CategoryProducts(category: "", topRated: [], others: [])
    )
    var searchResult: Result<[Product], Error> = .success([])
    var productResult: Result<Product, Error> = .failure(APIError.invalidData)
    var enquiryResult: Result<Void, Error> = .success(())

    private(set) var requestedCategoryNames: [String] = []
    private(set) var searchedTerms: [String] = []
    private(set) var requestedProductIds: [Int] = []
    private(set) var submittedEnquiries: [Enquiry] = []

    func featuredProducts() async throws -> [Product] {
        return try featuredResult.get()
    }

    func categories() async throws -> [String] {
        return try categoriesResult.get()
    }

    func categoryProducts(categoryName: String) async throws -> CategoryProducts {
        requestedCategoryNames.append(categoryName)
        return try categoryProductsResult.get()
    }

    func searchProducts(term: String) async throws -> [Product] {
        searchedTerms.append(term)
        return try searchResult.get()
    }

    func product(id: Int) async throws -> Product {
        requestedProductIds.append(id)
        return try productResult.get()
    }

    func submitEnquiry(_ enquiry: Enquiry) async throws {
        submittedEnquiries.append(enquiry)
        try enquiryResult.get()
    }
}

// An error our code does not know, to test the general message.
struct UnknownTestError: Error {}

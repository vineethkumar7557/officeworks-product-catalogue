import XCTest
import Foundation
@testable import CatalogueApp

@MainActor
final class CategoryViewModelTests: XCTestCase {

    private func makeResult(topRatedIds: [Int], otherIds: [Int]) -> CategoryProducts {
        return CategoryProducts(
            category: "jewelery",
            topRated: topRatedIds.map { TestData.makeProduct(id: $0) },
            others: otherIds.map { TestData.makeProduct(id: $0) }
        )
    }

    func testTitleIsTheReadableCategoryName() {
        let viewModel = CategoryViewModel(categoryName: "men's clothing", apiClient: MockAPIClient())

        XCTAssertEqual(viewModel.title, "Men's Clothing")
    }

    func testLoadAsksForThatCategory() async {
        let api = MockAPIClient()
        let viewModel = CategoryViewModel(categoryName: "men's clothing", apiClient: api)

        await viewModel.load()

        XCTAssertEqual(api.requestedCategoryNames, ["men's clothing"])
    }

    func testTopRatedComesFirstThenTheOthers() async {
        let api = MockAPIClient()
        api.categoryProductsResult = .success(makeResult(topRatedIds: [1, 2, 3], otherIds: [4, 5]))
        let viewModel = CategoryViewModel(categoryName: "jewelery", apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.sections.map { $0.title }, ["Top rated", "More products"])
        XCTAssertEqual(viewModel.sections[0].products.map { $0.id }, [1, 2, 3])
        XCTAssertEqual(viewModel.sections[1].products.map { $0.id }, [4, 5])
    }

    func testAnEmptyGroupIsLeftOut() async {
        let api = MockAPIClient()
        api.categoryProductsResult = .success(makeResult(topRatedIds: [1, 2], otherIds: []))
        let viewModel = CategoryViewModel(categoryName: "jewelery", apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.sections.map { $0.title }, ["Top rated"])
    }

    func testNoProductsGivesTheEmptyState() async {
        let api = MockAPIClient()
        api.categoryProductsResult = .success(makeResult(topRatedIds: [], otherIds: []))
        let viewModel = CategoryViewModel(categoryName: "jewelery", apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
        XCTAssertTrue(viewModel.sections.isEmpty)
    }

    func testAnUnknownCategoryShowsTheBackendMessage() async {
        let api = MockAPIClient()
        let error = APIError.server(statusCode: 404, code: "NOT_FOUND", message: "Category was not found.")
        api.categoryProductsResult = .failure(error)
        let viewModel = CategoryViewModel(categoryName: "nope", apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed("Category was not found."))
        XCTAssertTrue(viewModel.sections.isEmpty)
    }

    func testCancellationIsNotShownAsAnError() async {
        let api = MockAPIClient()
        api.categoryProductsResult = .failure(CancellationError())
        let viewModel = CategoryViewModel(categoryName: "jewelery", apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loading)
    }
}

import XCTest
import Foundation
@testable import CatalogueApp

@MainActor
final class HomeViewModelTests: XCTestCase {

    func testStartsInTheLoadingState() {
        let viewModel = HomeViewModel(apiClient: MockAPIClient())

        XCTAssertEqual(viewModel.state, .loading)
    }

    func testLoadShowsFeaturedProductsAndCategories() async {
        let api = MockAPIClient()
        let products = [TestData.makeProduct(id: 1), TestData.makeProduct(id: 2)]
        api.featuredResult = .success(products)
        api.categoriesResult = .success(["jewelery", "electronics"])
        let viewModel = HomeViewModel(apiClient: api)
        var seenStates: [ViewState<HomeContent>] = []
        viewModel.onStateChange = { seenStates.append($0) }

        await viewModel.load()

        let expected = HomeContent(featuredProducts: products, categories: ["jewelery", "electronics"])
        XCTAssertEqual(viewModel.state, .loaded(expected))
        XCTAssertEqual(seenStates, [.loading, .loaded(expected)])
    }

    func testNothingToShowGivesTheEmptyState() async {
        let viewModel = HomeViewModel(apiClient: MockAPIClient())

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testOnlyCategoriesStillCountsAsContent() async {
        let api = MockAPIClient()
        api.categoriesResult = .success(["jewelery"])
        let viewModel = HomeViewModel(apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded(HomeContent(featuredProducts: [], categories: ["jewelery"])))
    }

    func testABackendErrorShowsItsMessage() async {
        let api = MockAPIClient()
        api.featuredResult = .failure(APIError.noConnection)
        let viewModel = HomeViewModel(apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed(APIError.noConnection.localizedDescription))
    }

    func testAnUnknownErrorShowsAGeneralMessage() async {
        let api = MockAPIClient()
        api.categoriesResult = .failure(UnknownTestError())
        let viewModel = HomeViewModel(apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed("Something went wrong. Please try again."))
    }

    func testCancellationIsNotShownAsAnError() async {
        let api = MockAPIClient()
        api.featuredResult = .failure(CancellationError())
        let viewModel = HomeViewModel(apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loading)
    }

    func testLoadingAgainAfterAnErrorRecovers() async {
        let api = MockAPIClient()
        api.featuredResult = .failure(APIError.noConnection)
        let viewModel = HomeViewModel(apiClient: api)
        await viewModel.load()

        api.featuredResult = .success([TestData.makeProduct(id: 1)])
        await viewModel.load()

        let expected = HomeContent(featuredProducts: [TestData.makeProduct(id: 1)], categories: [])
        XCTAssertEqual(viewModel.state, .loaded(expected))
    }
}

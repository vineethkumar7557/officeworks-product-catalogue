import XCTest
import Foundation
@testable import CatalogueApp

final class SearchTermTests: XCTestCase {

    func testNothingTypedGivesNil() {
        XCTAssertNil(SearchTerm.cleaned(nil))
        XCTAssertNil(SearchTerm.cleaned(""))
    }

    func testOnlySpacesGivesNil() {
        XCTAssertNil(SearchTerm.cleaned("   \n "))
    }

    func testSpacesAroundTheTextAreRemoved() {
        XCTAssertEqual(SearchTerm.cleaned("  jacket "), "jacket")
    }

    func testSpacesInsideStayAsTheyAre() {
        XCTAssertEqual(SearchTerm.cleaned("mens jacket"), "mens jacket")
    }
}

@MainActor
final class SearchViewModelTests: XCTestCase {

    func testLoadSearchesForTheTerm() async {
        let api = MockAPIClient()
        let viewModel = SearchViewModel(term: "jacket", apiClient: api)

        await viewModel.load()

        XCTAssertEqual(api.searchedTerms, ["jacket"])
    }

    func testMatchesAreShownWithACountHeader() async {
        let api = MockAPIClient()
        api.searchResult = .success([TestData.makeProduct(id: 1), TestData.makeProduct(id: 2)])
        let viewModel = SearchViewModel(term: "jacket", apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.sections.count, 1)
        XCTAssertEqual(viewModel.sections[0].title, "2 results for “jacket”")
        XCTAssertEqual(viewModel.sections[0].products.map { $0.id }, [1, 2])
    }

    func testOneMatchSaysResultNotResults() async {
        let api = MockAPIClient()
        api.searchResult = .success([TestData.makeProduct(id: 1)])
        let viewModel = SearchViewModel(term: "jacket", apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.sections[0].title, "1 result for “jacket”")
    }

    func testNoMatchesGivesTheEmptyStateAndAFriendlyMessage() async {
        let viewModel = SearchViewModel(term: "zzz", apiClient: MockAPIClient())

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
        XCTAssertTrue(viewModel.sections.isEmpty)
        XCTAssertEqual(viewModel.emptyMessage, "No products match “zzz”. Try a different word.")
    }

    func testABackendErrorShowsItsMessage() async {
        let api = MockAPIClient()
        api.searchResult = .failure(APIError.server(statusCode: 400, code: "VALIDATION_ERROR", message: "Please type a word."))
        let viewModel = SearchViewModel(term: "x", apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed("Please type a word."))
    }

    func testNoInternetShowsTheConnectionMessage() async {
        let api = MockAPIClient()
        api.searchResult = .failure(APIError.noConnection)
        let viewModel = SearchViewModel(term: "x", apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed(APIError.noConnection.localizedDescription))
    }

    func testCancellationIsNotShownAsAnError() async {
        let api = MockAPIClient()
        api.searchResult = .failure(CancellationError())
        let viewModel = SearchViewModel(term: "x", apiClient: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loading)
    }
}

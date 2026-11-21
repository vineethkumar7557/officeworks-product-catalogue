import XCTest
import UIKit
@testable import CatalogueApp

@MainActor
final class HomeViewControllerTests: XCTestCase {

    private func makeHome(api: MockAPIClient) -> HomeViewController {
        let home = HomeViewController(viewModel: HomeViewModel(apiClient: api))
        prepare(home)
        return home
    }

    private func findCollectionView(of home: HomeViewController) throws -> UICollectionView {
        return try XCTUnwrap(home.view.findView(ofType: UICollectionView.self))
    }

    func testShowsFeaturedProductsAndCategories() async throws {
        let api = MockAPIClient()
        api.featuredResult = .success([TestData.makeProduct(id: 1), TestData.makeProduct(id: 2)])
        api.categoriesResult = .success(["jewelery", "electronics", "women's clothing"])
        let home = makeHome(api: api)
        let collectionView = try findCollectionView(of: home)

        let loaded = await waitUntil { !collectionView.isHidden && collectionView.numberOfItems(inSection: 0) == 2 }

        XCTAssertTrue(loaded)
        XCTAssertEqual(collectionView.numberOfItems(inSection: 1), 3)
    }

    func testTappingATileReportsTheProduct() async throws {
        let api = MockAPIClient()
        api.featuredResult = .success([TestData.makeProduct(id: 1), TestData.makeProduct(id: 2)])
        let home = makeHome(api: api)
        let collectionView = try findCollectionView(of: home)
        var tappedIds: [Int] = []
        home.onProductSelected = { tappedIds.append($0.id) }
        _ = await waitUntil { collectionView.numberOfItems(inSection: 0) == 2 }

        collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: IndexPath(item: 1, section: 0))

        XCTAssertEqual(tappedIds, [2])
    }

    func testTappingACategoryReportsItsName() async throws {
        let api = MockAPIClient()
        api.categoriesResult = .success(["jewelery", "electronics"])
        let home = makeHome(api: api)
        let collectionView = try findCollectionView(of: home)
        var tappedNames: [String] = []
        home.onCategorySelected = { tappedNames.append($0) }
        _ = await waitUntil { collectionView.numberOfItems(inSection: 1) == 2 }

        collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: IndexPath(item: 0, section: 1))

        XCTAssertEqual(tappedNames, ["jewelery"])
    }

    func testAnErrorShowsTheMessageAndTryAgainLoadsAgain() async throws {
        let api = MockAPIClient()
        api.featuredResult = .failure(APIError.noConnection)
        let home = makeHome(api: api)
        let collectionView = try findCollectionView(of: home)

        let errorShown = await waitUntil { home.view.hasVisibleLabel(withText: APIError.noConnection.localizedDescription) }
        XCTAssertTrue(errorShown)
        XCTAssertTrue(collectionView.isHidden)

        api.featuredResult = .success([TestData.makeProduct(id: 1)])
        let retryButton = try XCTUnwrap(home.view.findButton(withTitle: "Try again"))
        retryButton.sendActions(for: .touchUpInside)

        let loaded = await waitUntil { !collectionView.isHidden && collectionView.numberOfItems(inSection: 0) == 1 }
        XCTAssertTrue(loaded)
    }

    func testNothingToShowGivesAFriendlyMessage() async {
        let home = makeHome(api: MockAPIClient())

        let messageShown = await waitUntil {
            home.view.hasVisibleLabel(withText: "There are no products to show right now.")
        }

        XCTAssertTrue(messageShown)
    }

    // MARK: - Search

    func testNothingIsSearchedWhileTyping() throws {
        let home = makeHome(api: MockAPIClient())
        let searchBar = try XCTUnwrap(home.navigationItem.searchController?.searchBar)
        var searchedTerms: [String] = []
        home.onSearch = { searchedTerms.append($0) }

        searchBar.text = "jacket"
        searchBar.delegate?.searchBar?(searchBar, textDidChange: "jacket")

        XCTAssertTrue(searchedTerms.isEmpty)
    }

    func testTappingSearchSendsTheCleanedTerm() throws {
        let home = makeHome(api: MockAPIClient())
        let searchBar = try XCTUnwrap(home.navigationItem.searchController?.searchBar)
        var searchedTerms: [String] = []
        home.onSearch = { searchedTerms.append($0) }

        searchBar.text = "  jacket "
        searchBar.delegate?.searchBarSearchButtonClicked?(searchBar)

        XCTAssertEqual(searchedTerms, ["jacket"])
    }

    func testTappingSearchWithNothingTypedDoesNothing() throws {
        let home = makeHome(api: MockAPIClient())
        let searchBar = try XCTUnwrap(home.navigationItem.searchController?.searchBar)
        var searchedTerms: [String] = []
        home.onSearch = { searchedTerms.append($0) }

        searchBar.text = "   "
        searchBar.delegate?.searchBarSearchButtonClicked?(searchBar)

        XCTAssertTrue(searchedTerms.isEmpty)
    }
}

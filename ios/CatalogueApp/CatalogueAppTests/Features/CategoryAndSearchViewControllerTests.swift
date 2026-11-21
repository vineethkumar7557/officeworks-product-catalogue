import XCTest
import UIKit
@testable import CatalogueApp

@MainActor
final class CategoryViewControllerTests: XCTestCase {

    private func makeScreen(api: MockAPIClient) -> CategoryViewController {
        let viewModel = CategoryViewModel(categoryName: "jewelery", apiClient: api)
        let screen = CategoryViewController(viewModel: viewModel)
        prepare(screen)
        return screen
    }

    func testShowsTopRatedThenTheOthersAndReportsTaps() async throws {
        let api = MockAPIClient()
        api.categoryProductsResult = .success(CategoryProducts(
            category: "jewelery",
            topRated: [TestData.makeProduct(id: 1), TestData.makeProduct(id: 2)],
            others: [TestData.makeProduct(id: 3)]
        ))
        let screen = makeScreen(api: api)
        let collectionView = try XCTUnwrap(screen.view.findView(ofType: UICollectionView.self))
        var tappedIds: [Int] = []
        screen.onProductSelected = { tappedIds.append($0.id) }

        let loaded = await waitUntil { collectionView.numberOfSections == 2 }

        XCTAssertTrue(loaded)
        XCTAssertEqual(screen.title, "Jewelery")
        XCTAssertEqual(collectionView.numberOfItems(inSection: 0), 2)
        XCTAssertEqual(collectionView.numberOfItems(inSection: 1), 1)

        collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: IndexPath(item: 0, section: 1))
        XCTAssertEqual(tappedIds, [3])
    }

    func testAnEmptyCategoryShowsAMessage() async {
        let screen = makeScreen(api: MockAPIClient())

        let messageShown = await waitUntil {
            screen.view.hasVisibleLabel(withText: "There are no products in this category yet.")
        }

        XCTAssertTrue(messageShown)
    }

    func testAnErrorShowsItsMessage() async {
        let api = MockAPIClient()
        api.categoryProductsResult = .failure(APIError.noConnection)
        let screen = makeScreen(api: api)

        let errorShown = await waitUntil {
            screen.view.hasVisibleLabel(withText: APIError.noConnection.localizedDescription)
        }

        XCTAssertTrue(errorShown)
    }
}

@MainActor
final class SearchViewControllerTests: XCTestCase {

    private func makeScreen(term: String, api: MockAPIClient) -> SearchViewController {
        let screen = SearchViewController(viewModel: SearchViewModel(term: term, apiClient: api))
        prepare(screen)
        return screen
    }

    func testShowsOnlyTheMatchesAndReportsTaps() async throws {
        let api = MockAPIClient()
        api.searchResult = .success([TestData.makeProduct(id: 5), TestData.makeProduct(id: 6)])
        let screen = makeScreen(term: "jacket", api: api)
        let collectionView = try XCTUnwrap(screen.view.findView(ofType: UICollectionView.self))
        var tappedIds: [Int] = []
        screen.onProductSelected = { tappedIds.append($0.id) }

        let loaded = await waitUntil { collectionView.numberOfSections == 1 }

        XCTAssertTrue(loaded)
        XCTAssertEqual(api.searchedTerms, ["jacket"])
        XCTAssertEqual(collectionView.numberOfItems(inSection: 0), 2)

        collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: IndexPath(item: 1, section: 0))
        XCTAssertEqual(tappedIds, [6])
    }

    func testNoMatchesShowsAFriendlyMessage() async {
        let screen = makeScreen(term: "zzz", api: MockAPIClient())

        let messageShown = await waitUntil {
            screen.view.hasVisibleLabel(withText: "No products match “zzz”. Try a different word.")
        }

        XCTAssertTrue(messageShown)
    }

    func testAnErrorOffersTryAgain() async {
        let api = MockAPIClient()
        api.searchResult = .failure(APIError.noConnection)
        let screen = makeScreen(term: "jacket", api: api)

        let retryShown = await waitUntil {
            if let button = screen.view.findButton(withTitle: "Try again") {
                return !button.isHiddenInHierarchy
            }
            return false
        }

        XCTAssertTrue(retryShown)
    }
}

import XCTest
import UIKit
@testable import CatalogueApp

@MainActor
final class AppRouterTests: XCTestCase {

    private struct Setup {
        let router: AppRouter
        let navigationController: UINavigationController
        let home: HomeViewController
    }

    // The window lets the navigation controller present the enquiry sheet.
    private func makeSetup() throws -> Setup {
        let navigationController = UINavigationController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        retainedWindows.append(window)

        let router = AppRouter(navigationController: navigationController, apiClient: MockAPIClient())
        router.start()
        let home = try XCTUnwrap(navigationController.viewControllers.first as? HomeViewController)
        return Setup(router: router, navigationController: navigationController, home: home)
    }

    private var retainedWindows: [UIWindow] = []

    func testStartShowsHomeAsTheOnlyScreen() throws {
        let setup = try makeSetup()

        XCTAssertEqual(setup.navigationController.viewControllers.count, 1)
    }

    func testTappingACategoryOpensTheCategoryPage() throws {
        let setup = try makeSetup()

        setup.home.onCategorySelected?("jewelery")

        XCTAssertTrue(setup.navigationController.topViewController is CategoryViewController)
        XCTAssertEqual(setup.navigationController.viewControllers.count, 2)
    }

    func testSearchOpensTheResults() throws {
        let setup = try makeSetup()

        setup.home.onSearch?("jacket")

        XCTAssertTrue(setup.navigationController.topViewController is SearchViewController)
    }

    func testTappingAProductOpensTheDetailsPage() throws {
        let setup = try makeSetup()

        setup.home.onProductSelected?(TestData.makeProduct(id: 3))

        XCTAssertTrue(setup.navigationController.topViewController is ProductDetailViewController)
    }

    func testProductsOnTheCategoryAndSearchPagesOpenDetailsToo() throws {
        let setup = try makeSetup()

        setup.home.onCategorySelected?("jewelery")
        let category = try XCTUnwrap(setup.navigationController.topViewController as? CategoryViewController)
        category.onProductSelected?(TestData.makeProduct(id: 1))
        XCTAssertTrue(setup.navigationController.topViewController is ProductDetailViewController)

        setup.navigationController.popToRootViewController(animated: false)
        setup.home.onSearch?("jacket")
        let search = try XCTUnwrap(setup.navigationController.topViewController as? SearchViewController)
        search.onProductSelected?(TestData.makeProduct(id: 2))
        XCTAssertTrue(setup.navigationController.topViewController is ProductDetailViewController)
    }

    func testEnquireOpensTheFormAndASuccessfulSendShowsThankYou() throws {
        let setup = try makeSetup()
        setup.home.onProductSelected?(TestData.makeProduct(id: 3))
        let details = try XCTUnwrap(setup.navigationController.topViewController as? ProductDetailViewController)

        details.onEnquire?(TestData.makeProduct(id: 3))

        let sheet = try XCTUnwrap(setup.navigationController.presentedViewController as? UINavigationController)
        let form = try XCTUnwrap(sheet.viewControllers.first as? EnquiryViewController)

        form.onSubmitted?()

        XCTAssertTrue(sheet.topViewController is ThankYouViewController)
    }
}

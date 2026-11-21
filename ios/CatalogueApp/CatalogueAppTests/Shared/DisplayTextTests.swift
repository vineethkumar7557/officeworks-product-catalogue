import XCTest
import Foundation
@testable import CatalogueApp

final class DisplayTextTests: XCTestCase {

    func testCategoryNameGetsCapitalLettersOnEachWord() {
        XCTAssertEqual("men's clothing".displayName, "Men's Clothing")
        XCTAssertEqual("jewelery".displayName, "Jewelery")
        XCTAssertEqual("electronics".displayName, "Electronics")
    }

    func testEmptyNameStaysEmpty() {
        XCTAssertEqual("".displayName, "")
    }

    func testPriceHasADollarSignAndTwoDecimals() {
        XCTAssertEqual(TestData.makeProduct().priceText, "$55.99")
        let cheap = Product(
            id: 1, title: "A", description: "B", price: 7, category: "C",
            imageUrl: "", rating: 1, ratingCount: 1
        )
        XCTAssertEqual(cheap.priceText, "$7.00")
    }

    func testRatingShowsOneDecimalAndTheNumberOfRatings() {
        XCTAssertEqual(TestData.makeProduct().ratingText, "★ 4.7 (500)")
    }

    func testViewStatesWithTheSameContentAreEqual() {
        XCTAssertEqual(ViewState<Int>.loaded(1), ViewState<Int>.loaded(1))
        XCTAssertNotEqual(ViewState<Int>.loaded(1), ViewState<Int>.loaded(2))
        XCTAssertNotEqual(ViewState<Int>.loading, ViewState<Int>.empty)
    }

    func testAnUnknownErrorGetsAGeneralMessage() {
        XCTAssertEqual(UnknownTestError().customerMessage, "Something went wrong. Please try again.")
        XCTAssertEqual(APIError.noConnection.customerMessage, APIError.noConnection.localizedDescription)
    }
}

import XCTest
import Foundation
@testable import CatalogueApp

final class ProductDetailViewModelTests: XCTestCase {

    func testTextsComeFromTheProduct() {
        let viewModel = ProductDetailViewModel(product: TestData.makeProduct(id: 3))

        XCTAssertEqual(viewModel.title, "Mens Cotton Jacket")
        XCTAssertEqual(viewModel.categoryText, "Men's Clothing")
        XCTAssertEqual(viewModel.priceText, "$55.99")
        XCTAssertEqual(viewModel.ratingText, "★ 4.7 (500)")
        XCTAssertEqual(viewModel.descriptionText, "Warm jacket")
        XCTAssertEqual(viewModel.imageURL?.absoluteString, "https://example.com/3.jpg")
    }
}

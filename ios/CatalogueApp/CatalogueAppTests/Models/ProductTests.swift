import XCTest
import Foundation
@testable import CatalogueApp

final class ProductTests: XCTestCase {

    func testDecodesTheShapeOurBackendSends() throws {
        let data = Data(TestData.productJSON.utf8)

        let product = try JSONDecoder().decode(Product.self, from: data)

        XCTAssertEqual(product.id, 3)
        XCTAssertEqual(product.title, "Mens Cotton Jacket")
        XCTAssertEqual(product.category, "men's clothing")
        XCTAssertEqual(product.price, 55.99)
        XCTAssertEqual(product.rating, 4.7)
        XCTAssertEqual(product.ratingCount, 500)
        XCTAssertEqual(product.imageUrl, "https://example.com/3.jpg")
    }

    func testImageURLIsBuiltFromTheImageText() {
        let product = TestData.makeProduct(id: 3)

        XCTAssertEqual(product.imageURL?.absoluteString, "https://example.com/3.jpg")
    }

    func testImageURLIsNilWhenTheTextIsEmpty() {
        let product = Product(
            id: 1, title: "A", description: "B", price: 1, category: "C",
            imageUrl: "", rating: 1, ratingCount: 1
        )

        XCTAssertNil(product.imageURL)
    }

    func testTwoProductsWithTheSameValuesAreEqual() {
        XCTAssertEqual(TestData.makeProduct(id: 1), TestData.makeProduct(id: 1))
        XCTAssertNotEqual(TestData.makeProduct(id: 1), TestData.makeProduct(id: 2))
    }
}

import XCTest
import Foundation
@testable import CatalogueApp

final class APIErrorTests: XCTestCase {

    func testEveryErrorHasATextACustomerCanRead() {
        let errors: [APIError] = [
            .invalidURL,
            .noConnection,
            .invalidData,
            .server(statusCode: 500, code: "INTERNAL_ERROR", message: "Something went wrong.")
        ]

        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }

    func testAServerErrorShowsTheMessageFromTheBackend() {
        let error = APIError.server(statusCode: 404, code: "NOT_FOUND", message: "Product 9 was not found.")

        XCTAssertEqual(error.localizedDescription, "Product 9 was not found.")
    }
}

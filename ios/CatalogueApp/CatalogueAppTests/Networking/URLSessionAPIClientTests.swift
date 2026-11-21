import XCTest
import Foundation
@testable import CatalogueApp

final class URLSessionAPIClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeClient() throws -> URLSessionAPIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let baseURL = try XCTUnwrap(URL(string: "http://test.local"))
        return URLSessionAPIClient(baseURL: baseURL, session: URLSession(configuration: configuration))
    }

    // Makes the pretend network answer every request with this status and text.
    private func answer(status: Int = 200, body: String, onRequest: ((URLRequest) -> Void)? = nil) {
        MockURLProtocol.handler = { request in
            onRequest?(request)
            guard
                let url = request.url,
                let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)
            else {
                throw URLError(.badURL)
            }
            return (response, Data(body.utf8))
        }
    }

    // Checks that an async operation fails with exactly this error.
    private func assertThrows<T>(
        _ expected: APIError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> T
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected \(expected), but nothing was thrown", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? APIError, expected, file: file, line: line)
        }
    }

    // MARK: - Reading data

    func testFeaturedProductsAsksTheFeaturedAddressAndReadsTheProducts() async throws {
        var sentRequest: URLRequest?
        answer(body: "{\"products\":[\(TestData.productJSON)]}") { sentRequest = $0 }

        let products = try await makeClient().featuredProducts()

        XCTAssertEqual(products.map { $0.title }, ["Mens Cotton Jacket"])
        XCTAssertEqual(sentRequest?.url?.absoluteString, "http://test.local/featured")
        XCTAssertEqual(sentRequest?.httpMethod, "GET")
        XCTAssertEqual(sentRequest?.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testCategoriesReadsTheNames() async throws {
        answer(body: "{\"categories\":[\"men's clothing\",\"jewelery\"]}")

        let categories = try await makeClient().categories()

        XCTAssertEqual(categories, ["men's clothing", "jewelery"])
    }

    func testCategoryProductsReadsTopRatedAndOthers() async throws {
        answer(body: """
        {"category":"jewelery","topRated":[\(TestData.productJSON)],"others":[]}
        """)

        let result = try await makeClient().categoryProducts(categoryName: "jewelery")

        XCTAssertEqual(result.category, "jewelery")
        XCTAssertEqual(result.topRated.count, 1)
        XCTAssertTrue(result.others.isEmpty)
    }

    func testCategoryNameWithSpaceAndApostropheIsSentSafely() async throws {
        var sentRequest: URLRequest?
        answer(body: "{\"category\":\"men's clothing\",\"topRated\":[],\"others\":[]}") { sentRequest = $0 }

        _ = try await makeClient().categoryProducts(categoryName: "men's clothing")

        let url = try XCTUnwrap(sentRequest?.url)
        XCTAssertEqual(url.path, "/categories/men's clothing/products")
        XCTAssertTrue(url.absoluteString.contains("%20"), "The space must be encoded")
        XCTAssertFalse(url.absoluteString.contains(" "))
    }

    func testCategoryNameWithASlashStaysOnePathPiece() async throws {
        var sentRequest: URLRequest?
        answer(body: "{\"category\":\"a/b\",\"topRated\":[],\"others\":[]}") { sentRequest = $0 }

        _ = try await makeClient().categoryProducts(categoryName: "a/b")

        XCTAssertTrue(sentRequest?.url?.absoluteString.contains("a%2Fb") ?? false)
    }

    func testSearchSendsTheTermAsTheQ() async throws {
        var sentRequest: URLRequest?
        answer(body: "{\"query\":\"x\",\"products\":[\(TestData.productJSON)]}") { sentRequest = $0 }

        let products = try await makeClient().searchProducts(term: "men's jacket")

        XCTAssertEqual(products.count, 1)
        let url = try XCTUnwrap(sentRequest?.url)
        XCTAssertEqual(url.path, "/products")
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "q" })?.value, "men's jacket")
    }

    func testProductAsksForThatId() async throws {
        var sentRequest: URLRequest?
        answer(body: TestData.productJSON) { sentRequest = $0 }

        let product = try await makeClient().product(id: 3)

        XCTAssertEqual(product.id, 3)
        XCTAssertEqual(sentRequest?.url?.absoluteString, "http://test.local/products/3")
    }

    // MARK: - Sending an enquiry

    func testSubmitEnquiryPostsJSON() async throws {
        var sentRequest: URLRequest?
        answer(status: 201, body: "{\"message\":\"Thank you\"}") { sentRequest = $0 }
        let enquiry = Enquiry(
            name: "Asha Rao", email: "asha@example.com", phone: "+91 98765 43210",
            message: "Is this in stock?", productId: 3
        )

        try await makeClient().submitEnquiry(enquiry)

        XCTAssertEqual(sentRequest?.httpMethod, "POST")
        XCTAssertEqual(sentRequest?.url?.absoluteString, "http://test.local/enquiries")
        XCTAssertEqual(sentRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        let body = try XCTUnwrap(sentRequest?.bodyData())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["name"] as? String, "Asha Rao")
        XCTAssertEqual(json["email"] as? String, "asha@example.com")
        XCTAssertEqual(json["phone"] as? String, "+91 98765 43210")
        XCTAssertEqual(json["message"] as? String, "Is this in stock?")
        XCTAssertEqual(json["productId"] as? Int, 3)
    }

    func testSubmitEnquiryLeavesOutAMissingPhone() async throws {
        var sentRequest: URLRequest?
        answer(status: 201, body: "{\"message\":\"Thank you\"}") { sentRequest = $0 }
        let enquiry = Enquiry(name: "Asha", email: "asha@example.com", phone: nil, message: "Hi", productId: 3)

        try await makeClient().submitEnquiry(enquiry)

        let body = try XCTUnwrap(sentRequest?.bodyData())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertNil(json["phone"])
    }

    // MARK: - Failures

    func testBackendErrorKeepsItsCodeAndMessage() async throws {
        answer(status: 404, body: "{\"error\":{\"code\":\"NOT_FOUND\",\"message\":\"Product 9 was not found.\"}}")
        let client = try makeClient()

        await assertThrows(.server(statusCode: 404, code: "NOT_FOUND", message: "Product 9 was not found.")) {
            try await client.product(id: 9)
        }
    }

    func testBackendErrorOnEnquiryIsReported() async throws {
        answer(status: 502, body: "{\"error\":{\"code\":\"UPSTREAM_ERROR\",\"message\":\"The email could not be sent.\"}}")
        let client = try makeClient()
        let enquiry = Enquiry(name: "A", email: "a@example.com", phone: nil, message: "Hi", productId: 3)

        await assertThrows(.server(statusCode: 502, code: "UPSTREAM_ERROR", message: "The email could not be sent.")) {
            try await client.submitEnquiry(enquiry)
        }
    }

    func testAnErrorThatIsNotOurFormatGetsAGeneralMessage() async throws {
        answer(status: 500, body: "<html>Oops</html>")
        let client = try makeClient()

        await assertThrows(
            .server(statusCode: 500, code: "UNKNOWN", message: "The server had a problem. Please try again.")
        ) {
            try await client.featuredProducts()
        }
    }

    func testDataWeCannotReadGivesInvalidData() async throws {
        answer(body: "{\"products\":\"not a list\"}")
        let client = try makeClient()

        await assertThrows(.invalidData) {
            try await client.featuredProducts()
        }
    }

    func testNoInternetGivesNoConnection() async throws {
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        let client = try makeClient()

        await assertThrows(.noConnection) {
            try await client.featuredProducts()
        }
    }

    func testACancelledRequestGivesCancellationErrorNotAnAPIError() async throws {
        MockURLProtocol.handler = { _ in throw URLError(.cancelled) }
        let client = try makeClient()

        do {
            _ = try await client.featuredProducts()
            XCTFail("Expected a CancellationError")
        } catch {
            XCTAssertTrue(error is CancellationError, "Got \(error)")
        }
    }
}

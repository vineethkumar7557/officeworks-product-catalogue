import Foundation

// The real APIClient. It talks to our backend with URLSession.
final class URLSessionAPIClient: APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // A path piece may not contain "/", so we take it out of the allowed characters.
    private static let pathPieceAllowed: CharacterSet = {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        return allowed
    }()

    // Tests pass their own session, so no real network is used.
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func featuredProducts() async throws -> [Product] {
        let response: ProductListResponse = try await get(pathPieces: ["featured"])
        return response.products
    }

    func categories() async throws -> [String] {
        let response: CategoryListResponse = try await get(pathPieces: ["categories"])
        return response.categories
    }

    func categoryProducts(categoryName: String) async throws -> CategoryProducts {
        return try await get(pathPieces: ["categories", categoryName, "products"])
    }

    func searchProducts(term: String) async throws -> [Product] {
        let response: ProductListResponse = try await get(
            pathPieces: ["products"],
            queryItems: [URLQueryItem(name: "q", value: term)]
        )
        return response.products
    }

    func product(id: Int) async throws -> Product {
        return try await get(pathPieces: ["products", String(id)])
    }

    func submitEnquiry(_ enquiry: Enquiry) async throws {
        var request = URLRequest(url: try makeURL(pathPieces: ["enquiries"]))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(enquiry)
        _ = try await send(request)
    }

    // MARK: - Helpers

    private func get<T: Decodable>(pathPieces: [String], queryItems: [URLQueryItem] = []) async throws -> T {
        var request = URLRequest(url: try makeURL(pathPieces: pathPieces, queryItems: queryItems))
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let data = try await send(request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.invalidData
        }
    }

    // Sends the request and turns every failure into an APIError.
    private func send(_ request: URLRequest) async throws -> Data {
        let result: (Data, URLResponse)
        do {
            result = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            // The screen stopped waiting (for example the user went back). This is not an error to show.
            throw CancellationError()
        } catch is URLError {
            throw APIError.noConnection
        }

        let (data, response) = result
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidData
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw serverError(statusCode: httpResponse.statusCode, data: data)
        }
        return data
    }

    // Reads the backend's standard error format. If the answer is something else, we use a general message.
    private func serverError(statusCode: Int, data: Data) -> APIError {
        if let body = try? decoder.decode(ErrorResponse.self, from: data) {
            return .server(statusCode: statusCode, code: body.error.code, message: body.error.message)
        }
        return .server(statusCode: statusCode, code: "UNKNOWN", message: "The server had a problem. Please try again.")
    }

    // Builds the address, and safely encodes spaces, apostrophes and so on (for example "men's clothing").
    private func makeURL(pathPieces: [String], queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        let encodedPieces = pathPieces.compactMap {
            $0.addingPercentEncoding(withAllowedCharacters: Self.pathPieceAllowed)
        }
        components.percentEncodedPath = "/" + encodedPieces.joined(separator: "/")
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }
        return url
    }
}

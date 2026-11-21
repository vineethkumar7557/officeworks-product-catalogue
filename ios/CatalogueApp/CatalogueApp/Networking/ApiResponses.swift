import Foundation

// The exact JSON shapes our backend sends. Only URLSessionAPIClient uses these.
struct ProductListResponse: Decodable {
    let products: [Product]
}

struct CategoryListResponse: Decodable {
    let categories: [String]
}

struct ErrorResponse: Decodable {
    struct Body: Decodable {
        let code: String
        let message: String
    }

    let error: Body
}

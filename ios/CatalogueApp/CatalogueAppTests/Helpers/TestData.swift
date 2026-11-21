import Foundation
@testable import CatalogueApp

// Sample data used by many tests.
enum TestData {
    // One product written exactly as our backend sends it.
    static let productJSON = """
    {"id":3,"title":"Mens Cotton Jacket","description":"Warm jacket","price":55.99,\
    "category":"men's clothing","imageUrl":"https://example.com/3.jpg","rating":4.7,"ratingCount":500}
    """

    static func makeProduct(
        id: Int = 3,
        title: String = "Mens Cotton Jacket",
        category: String = "men's clothing",
        rating: Double = 4.7
    ) -> Product {
        return Product(
            id: id,
            title: title,
            description: "Warm jacket",
            price: 55.99,
            category: category,
            imageUrl: "https://example.com/\(id).jpg",
            rating: rating,
            ratingCount: 500
        )
    }
}

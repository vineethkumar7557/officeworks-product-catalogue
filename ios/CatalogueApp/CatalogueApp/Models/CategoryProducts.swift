import Foundation

// A category page: the top rated products first, then the other products of that category.
struct CategoryProducts: Codable, Equatable {
    let category: String
    let topRated: [Product]
    let others: [Product]
}

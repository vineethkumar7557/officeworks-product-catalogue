import Foundation

// A titled group of products on a screen, for example "Top rated".
struct ProductSection: Equatable {
    let title: String
    let products: [Product]
}

import Foundation

// How a product's numbers are written on screen.
extension Product {
    // The catalogue has no currency field, so we show a plain dollar sign.
    var priceText: String {
        return String(format: "$%.2f", price)
    }

    var ratingText: String {
        return String(format: "★ %.1f (%ld)", rating, ratingCount)
    }
}

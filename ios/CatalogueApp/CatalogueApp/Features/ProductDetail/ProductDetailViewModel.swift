import Foundation

// The texts the details page shows. The product is already loaded, so there is nothing to wait for.
struct ProductDetailViewModel {
    let product: Product

    var title: String { product.title }
    var categoryText: String { product.category.displayName }
    var priceText: String { product.priceText }
    var ratingText: String { product.ratingText }
    var descriptionText: String { product.description }
    var imageURL: URL? { product.imageURL }
}

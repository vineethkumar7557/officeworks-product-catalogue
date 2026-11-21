import Foundation

// The product shape that OUR backend sends. It is the only product shape the app knows.
struct Product: Codable, Hashable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let category: String
    let imageUrl: String
    let rating: Double
    let ratingCount: Int

    // The image address as a URL. It is nil when the text is not a valid address.
    var imageURL: URL? {
        URL(string: imageUrl)
    }
}

import Foundation

// What the customer fills in on the enquiry form. A missing phone number is simply left out of the JSON.
struct Enquiry: Encodable, Equatable {
    let name: String
    let email: String
    let phone: String?
    let message: String
    let productId: Int
}

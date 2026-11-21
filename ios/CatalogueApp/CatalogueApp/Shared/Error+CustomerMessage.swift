import Foundation

extension Error {
    // A short text a customer can read. Our own errors already carry one.
    var customerMessage: String {
        if let apiError = self as? APIError {
            return apiError.localizedDescription
        }
        return "Something went wrong. Please try again."
    }
}

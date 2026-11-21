import Foundation

// Everything that can go wrong when talking to our backend.
enum APIError: Error, Equatable {
    case invalidURL
    case noConnection
    case invalidData
    // The backend answered with an error. "code" and "message" come from its standard error format.
    case server(statusCode: Int, code: String, message: String)
}

// The text a customer can read on screen.
extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Something is wrong with the app settings. Please contact support."
        case .noConnection:
            return "We can't reach the server. Please check your connection and try again."
        case .invalidData:
            return "We received something we could not read. Please try again."
        case .server(_, _, let message):
            return message
        }
    }
}

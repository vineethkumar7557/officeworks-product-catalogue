import Foundation

// Settings that can change between environments. Change them in Info.plist, not in code.
enum AppConfig {
    // Where OUR backend runs. The app never talks to Fake Store directly.
    // Use just scheme://host:port here, with no extra path.
    static var apiBaseURL: URL {
        let text = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "http://localhost:3000"
        guard let url = URL(string: text) else {
            // A wrong address is a mistake in the settings, so we stop at once instead of limping on.
            preconditionFailure("API_BASE_URL in Info.plist is not a valid address: \(text)")
        }
        return url
    }
}

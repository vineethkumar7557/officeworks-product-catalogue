import Foundation

enum EnquiryField: CaseIterable, Hashable {
    case name
    case email
    case phone
    case message
}

// What the customer typed, exactly as typed.
struct EnquiryForm: Equatable {
    var name = ""
    var email = ""
    var phone = ""
    var message = ""
}

// Checks the form before anything is sent. These rules match the backend's rules,
// so the customer gets a quick answer. The backend still checks everything again.
enum EnquiryValidator {
    static let maxNameLength = 100
    static let maxEmailLength = 254
    static let maxMessageLength = 2000

    private static let emailPattern = "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"
    private static let phonePattern = "^[0-9+()\\-\\s]{6,20}$"

    // Returns a message for every field that has a problem. An empty result means the form is fine.
    static func errors(for form: EnquiryForm) -> [EnquiryField: String] {
        var errors: [EnquiryField: String] = [:]

        let name = trimmed(form.name)
        if name.isEmpty {
            errors[.name] = "Please enter your name."
        } else if name.count > maxNameLength {
            errors[.name] = "Name must be \(maxNameLength) characters or fewer."
        }

        let email = trimmed(form.email)
        if email.isEmpty {
            errors[.email] = "Please enter your email address."
        } else if email.count > maxEmailLength || !matches(email, pattern: emailPattern) {
            errors[.email] = "Please enter a valid email address."
        }

        let phone = trimmed(form.phone)
        if !phone.isEmpty && !matches(phone, pattern: phonePattern) {
            errors[.phone] = "Use 6 to 20 characters: digits, spaces and + ( ) -"
        }

        let message = trimmed(form.message)
        if message.isEmpty {
            errors[.message] = "Please enter your message."
        } else if message.count > maxMessageLength {
            errors[.message] = "Message must be \(maxMessageLength) characters or fewer."
        }

        return errors
    }

    static func trimmed(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func matches(_ text: String, pattern: String) -> Bool {
        return text.range(of: pattern, options: .regularExpression) != nil
    }
}

import Foundation

// Checks and sends one enquiry about one product. It knows nothing about UIKit.
@MainActor
final class EnquiryViewModel {
    enum State: Equatable {
        case editing
        case invalid([EnquiryField: String])
        case submitting
        case submitted
        case failed(String)
    }

    let product: Product
    private let apiClient: APIClient

    // The screen sets this to be told when the state changes.
    var onStateChange: ((State) -> Void)?

    private(set) var state: State = .editing {
        didSet { onStateChange?(state) }
    }

    init(product: Product, apiClient: APIClient) {
        self.product = product
        self.apiClient = apiClient
    }

    func submit(_ form: EnquiryForm) async {
        // A second tap while the first is still being sent does nothing.
        if state == .submitting { return }

        let errors = EnquiryValidator.errors(for: form)
        if !errors.isEmpty {
            state = .invalid(errors)
            return
        }

        let phone = EnquiryValidator.trimmed(form.phone)
        let enquiry = Enquiry(
            name: EnquiryValidator.trimmed(form.name),
            email: EnquiryValidator.trimmed(form.email),
            phone: phone.isEmpty ? nil : phone,
            message: EnquiryValidator.trimmed(form.message),
            productId: product.id
        )

        state = .submitting
        do {
            try await apiClient.submitEnquiry(enquiry)
            state = .submitted
        } catch is CancellationError {
            state = .editing
        } catch {
            state = .failed(error.customerMessage)
        }
    }
}

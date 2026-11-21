import XCTest
import Foundation
@testable import CatalogueApp

@MainActor
final class EnquiryViewModelTests: XCTestCase {

    private func validForm() -> EnquiryForm {
        return EnquiryForm(
            name: "  Asha Rao ",
            email: " asha@example.com ",
            phone: " +61 2 9999 0000 ",
            message: " Is this in stock? "
        )
    }

    private func makeViewModel(api: MockAPIClient) -> EnquiryViewModel {
        return EnquiryViewModel(product: TestData.makeProduct(id: 7), apiClient: api)
    }

    func testStartsInTheEditingState() {
        XCTAssertEqual(makeViewModel(api: MockAPIClient()).state, .editing)
    }

    func testAnInvalidFormShowsErrorsAndSendsNothing() async {
        let api = MockAPIClient()
        let viewModel = makeViewModel(api: api)

        await viewModel.submit(EnquiryForm())

        guard case .invalid(let errors) = viewModel.state else {
            return XCTFail("Expected the invalid state, got \(viewModel.state)")
        }
        XCTAssertEqual(Set(errors.keys), [.name, .email, .message])
        XCTAssertTrue(api.submittedEnquiries.isEmpty)
    }

    func testAGoodFormIsSentWithTrimmedTextAndTheProductId() async {
        let api = MockAPIClient()
        let viewModel = makeViewModel(api: api)
        var seenStates: [EnquiryViewModel.State] = []
        viewModel.onStateChange = { seenStates.append($0) }

        await viewModel.submit(validForm())

        XCTAssertEqual(seenStates, [.submitting, .submitted])
        XCTAssertEqual(api.submittedEnquiries, [
            Enquiry(
                name: "Asha Rao",
                email: "asha@example.com",
                phone: "+61 2 9999 0000",
                message: "Is this in stock?",
                productId: 7
            )
        ])
    }

    func testABlankPhoneIsLeftOut() async {
        let api = MockAPIClient()
        let viewModel = makeViewModel(api: api)
        var form = validForm()
        form.phone = "   "

        await viewModel.submit(form)

        XCTAssertEqual(api.submittedEnquiries.count, 1)
        XCTAssertNil(api.submittedEnquiries[0].phone)
    }

    func testABackendErrorShowsItsMessageAndTheCustomerCanTryAgain() async {
        let api = MockAPIClient()
        api.enquiryResult = .failure(
            APIError.server(statusCode: 429, code: "TOO_MANY_REQUESTS", message: "Too many enquiries. Please try again later.")
        )
        let viewModel = makeViewModel(api: api)

        await viewModel.submit(validForm())
        XCTAssertEqual(viewModel.state, .failed("Too many enquiries. Please try again later."))

        api.enquiryResult = .success(())
        await viewModel.submit(validForm())
        XCTAssertEqual(viewModel.state, .submitted)
        XCTAssertEqual(api.submittedEnquiries.count, 2)
    }

    func testNoConnectionShowsTheConnectionMessage() async {
        let api = MockAPIClient()
        api.enquiryResult = .failure(APIError.noConnection)
        let viewModel = makeViewModel(api: api)

        await viewModel.submit(validForm())

        XCTAssertEqual(viewModel.state, .failed(APIError.noConnection.localizedDescription))
    }

    func testAnUnknownErrorShowsAGeneralMessage() async {
        let api = MockAPIClient()
        api.enquiryResult = .failure(UnknownTestError())
        let viewModel = makeViewModel(api: api)

        await viewModel.submit(validForm())

        XCTAssertEqual(viewModel.state, .failed("Something went wrong. Please try again."))
    }

    func testCancellationGoesBackToEditing() async {
        let api = MockAPIClient()
        api.enquiryResult = .failure(CancellationError())
        let viewModel = makeViewModel(api: api)

        await viewModel.submit(validForm())

        XCTAssertEqual(viewModel.state, .editing)
    }

    func testFixingAnInvalidFormAndSendingAgainWorks() async {
        let api = MockAPIClient()
        let viewModel = makeViewModel(api: api)
        var form = validForm()
        form.email = "nope"

        await viewModel.submit(form)
        form.email = "asha@example.com"
        await viewModel.submit(form)

        XCTAssertEqual(viewModel.state, .submitted)
        XCTAssertEqual(api.submittedEnquiries.count, 1)
    }
}

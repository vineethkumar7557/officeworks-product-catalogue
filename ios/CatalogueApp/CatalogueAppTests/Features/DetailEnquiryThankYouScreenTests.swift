import XCTest
import UIKit
@testable import CatalogueApp

@MainActor
final class ProductDetailViewControllerTests: XCTestCase {

    func testShowsTheProductAndTheEnquireButtonReportsTheProduct() throws {
        let product = TestData.makeProduct(id: 3)
        let screen = ProductDetailViewController(viewModel: ProductDetailViewModel(product: product))
        prepare(screen)
        var enquiredIds: [Int] = []
        screen.onEnquire = { enquiredIds.append($0.id) }

        XCTAssertTrue(screen.view.hasVisibleLabel(withText: "Mens Cotton Jacket"))
        XCTAssertTrue(screen.view.hasVisibleLabel(withText: "$55.99"))
        XCTAssertTrue(screen.view.hasVisibleLabel(withText: "Warm jacket"))

        let button = try XCTUnwrap(screen.view.findButton(withTitle: "Enquire"))
        button.sendActions(for: .touchUpInside)

        XCTAssertEqual(enquiredIds, [3])
    }
}

@MainActor
final class EnquiryViewControllerTests: XCTestCase {

    private func makeScreen(api: MockAPIClient) -> (EnquiryViewController, EnquiryViewModel) {
        let viewModel = EnquiryViewModel(product: TestData.makeProduct(id: 7), apiClient: api)
        let screen = EnquiryViewController(viewModel: viewModel)
        prepare(screen)
        return (screen, viewModel)
    }

    private func validForm() -> EnquiryForm {
        return EnquiryForm(name: "Asha", email: "asha@example.com", phone: "", message: "Is this in stock?")
    }

    func testFillingTheFormAndTappingSendSubmitsTheEnquiry() async throws {
        let api = MockAPIClient()
        let (screen, _) = makeScreen(api: api)
        var submittedCount = 0
        screen.onSubmitted = { submittedCount += 1 }

        try XCTUnwrap(screen.view.findTextField(withPlaceholder: "Your name")).text = "Asha Rao"
        try XCTUnwrap(screen.view.findTextField(withPlaceholder: "you@example.com")).text = "asha@example.com"
        try XCTUnwrap(screen.view.findViews(ofType: UITextView.self).first).text = "Is this in stock?"
        try XCTUnwrap(screen.view.findButton(withTitle: "Send enquiry")).sendActions(for: .touchUpInside)

        let sent = await waitUntil { submittedCount == 1 }

        XCTAssertTrue(sent)
        XCTAssertEqual(api.submittedEnquiries.count, 1)
        XCTAssertEqual(api.submittedEnquiries.first?.name, "Asha Rao")
        XCTAssertEqual(api.submittedEnquiries.first?.productId, 7)
        XCTAssertNil(api.submittedEnquiries.first?.phone)
    }

    func testAnEmptyFormShowsErrorsNextToTheFields() async {
        let api = MockAPIClient()
        let (screen, viewModel) = makeScreen(api: api)
        var submittedCount = 0
        screen.onSubmitted = { submittedCount += 1 }

        await viewModel.submit(EnquiryForm())

        XCTAssertTrue(screen.view.hasVisibleLabel(withText: "Please enter your name."))
        XCTAssertTrue(screen.view.hasVisibleLabel(withText: "Please enter your email address."))
        XCTAssertTrue(screen.view.hasVisibleLabel(withText: "Please enter your message."))
        XCTAssertEqual(submittedCount, 0)
        XCTAssertTrue(api.submittedEnquiries.isEmpty)
    }

    func testABackendErrorShowsItsMessageAndDoesNotReportSubmitted() async {
        let api = MockAPIClient()
        api.enquiryResult = .failure(APIError.noConnection)
        let (screen, viewModel) = makeScreen(api: api)
        var submittedCount = 0
        screen.onSubmitted = { submittedCount += 1 }

        await viewModel.submit(validForm())

        XCTAssertTrue(screen.view.hasVisibleLabel(withText: APIError.noConnection.localizedDescription))
        XCTAssertEqual(submittedCount, 0)
    }

    func testErrorsDisappearOnceTheFormIsFixed() async {
        let api = MockAPIClient()
        let (screen, viewModel) = makeScreen(api: api)

        await viewModel.submit(EnquiryForm())
        await viewModel.submit(validForm())

        XCTAssertFalse(screen.view.hasVisibleLabel(withText: "Please enter your name."))
    }

    func testCancelReportsCancel() throws {
        let (screen, _) = makeScreen(api: MockAPIClient())
        var cancelCount = 0
        screen.onCancel = { cancelCount += 1 }

        let action = try XCTUnwrap(screen.navigationItem.leftBarButtonItem?.primaryAction)
        action.performWithSender(nil, target: nil)

        XCTAssertEqual(cancelCount, 1)
    }
}

@MainActor
final class ThankYouViewControllerTests: XCTestCase {

    func testSaysThankYouAndDoneReportsDone() throws {
        let screen = ThankYouViewController(productTitle: "Mens Cotton Jacket")
        prepare(screen)
        var doneCount = 0
        screen.onDone = { doneCount += 1 }

        XCTAssertTrue(screen.view.hasVisibleLabel(withText: "Thank you!"))
        XCTAssertTrue(screen.view.findViews(ofType: UILabel.self).contains { ($0.text ?? "").contains("Mens Cotton Jacket") })

        try XCTUnwrap(screen.view.findButton(withTitle: "Done")).sendActions(for: .touchUpInside)
        XCTAssertEqual(doneCount, 1)
    }
}

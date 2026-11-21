import XCTest
import Foundation
@testable import CatalogueApp

final class EnquiryValidatorTests: XCTestCase {

    private func validForm() -> EnquiryForm {
        return EnquiryForm(
            name: "Asha Rao",
            email: "asha@example.com",
            phone: "+61 2 9999 0000",
            message: "Is this in stock?"
        )
    }

    func testAGoodFormHasNoErrors() {
        XCTAssertTrue(EnquiryValidator.errors(for: validForm()).isEmpty)
    }

    func testPhoneIsOptional() {
        var form = validForm()
        form.phone = ""
        XCTAssertTrue(EnquiryValidator.errors(for: form).isEmpty)

        form.phone = "   "
        XCTAssertTrue(EnquiryValidator.errors(for: form).isEmpty)
    }

    func testEmptyFormReportsEveryRequiredField() {
        let errors = EnquiryValidator.errors(for: EnquiryForm())

        XCTAssertEqual(Set(errors.keys), [.name, .email, .message])
    }

    func testNameWithOnlySpacesIsMissing() {
        var form = validForm()
        form.name = "   \n "

        XCTAssertNotNil(EnquiryValidator.errors(for: form)[.name])
    }

    func testNameLengthLimit() {
        var form = validForm()
        form.name = String(repeating: "a", count: 100)
        XCTAssertNil(EnquiryValidator.errors(for: form)[.name])

        form.name = String(repeating: "a", count: 101)
        XCTAssertNotNil(EnquiryValidator.errors(for: form)[.name])
    }

    func testEmailMustLookLikeAnEmail() {
        var form = validForm()

        for bad in ["bad", "a@b", "@example.com", "a b@example.com", "a@@example.com"] {
            form.email = bad
            XCTAssertNotNil(EnquiryValidator.errors(for: form)[.email], "\(bad) should be rejected")
        }
        for good in ["a@b.com", "first.last+tag@mail.example.com.au", "  a@b.com  "] {
            form.email = good
            XCTAssertNil(EnquiryValidator.errors(for: form)[.email], "\(good) should be accepted")
        }
    }

    func testEmailLengthLimit() {
        var form = validForm()
        form.email = String(repeating: "a", count: 250) + "@b.co"

        XCTAssertNotNil(EnquiryValidator.errors(for: form)[.email])
    }

    func testPhoneRules() {
        var form = validForm()

        for bad in ["12345", "abc123456", String(repeating: "1", count: 21)] {
            form.phone = bad
            XCTAssertNotNil(EnquiryValidator.errors(for: form)[.phone], "\(bad) should be rejected")
        }
        for good in ["123456", "+61 (2) 9999-0000", String(repeating: "1", count: 20)] {
            form.phone = good
            XCTAssertNil(EnquiryValidator.errors(for: form)[.phone], "\(good) should be accepted")
        }
    }

    func testMessageRules() {
        var form = validForm()

        form.message = "  "
        XCTAssertNotNil(EnquiryValidator.errors(for: form)[.message])

        form.message = String(repeating: "m", count: 2000)
        XCTAssertNil(EnquiryValidator.errors(for: form)[.message])

        form.message = String(repeating: "m", count: 2001)
        XCTAssertNotNil(EnquiryValidator.errors(for: form)[.message])
    }

    func testOnlyTheFieldsWithProblemsAreReported() {
        var form = validForm()
        form.email = "nope"

        XCTAssertEqual(Set(EnquiryValidator.errors(for: form).keys), [.email])
    }
}

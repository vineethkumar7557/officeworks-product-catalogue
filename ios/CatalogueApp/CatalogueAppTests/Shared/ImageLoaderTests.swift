import XCTest
import UIKit
@testable import CatalogueApp

// ImageLoader uses the shared URLSession, so these tests put the pretend network in front of it for the length of each test.
@MainActor
final class ImageLoaderTests: XCTestCase {

    private func makePNGData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        return image.pngData() ?? Data()
    }

    private func answer(with data: Data) {
        MockURLProtocol.handler = { request in
            guard
                let url = request.url,
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            else {
                throw URLError(.badURL)
            }
            return (response, data)
        }
    }

    private func useThePretendNetwork() {
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    private func stopUsingThePretendNetwork() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.handler = nil
    }

    func testAPictureIsDownloadedOnceAndThenRemembered() async throws {
        useThePretendNetwork()
        defer { stopUsingThePretendNetwork() }
        let url = try XCTUnwrap(URL(string: "https://images.test/remembered.png"))
        answer(with: makePNGData())

        let first = await ImageLoader.load(url)
        XCTAssertNotNil(first)
        XCTAssertNotNil(ImageLoader.cachedImage(for: url))

        // The network now fails, but the picture is remembered.
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        let second = await ImageLoader.load(url)
        XCTAssertNotNil(second)
    }

    func testDataThatIsNotAPictureGivesNilAndIsNotRemembered() async throws {
        useThePretendNetwork()
        defer { stopUsingThePretendNetwork() }
        let url = try XCTUnwrap(URL(string: "https://images.test/broken.png"))
        answer(with: Data("not a picture".utf8))

        let image = await ImageLoader.load(url)

        XCTAssertNil(image)
        XCTAssertNil(ImageLoader.cachedImage(for: url))
    }

    func testANetworkErrorGivesNil() async throws {
        useThePretendNetwork()
        defer { stopUsingThePretendNetwork() }
        let url = try XCTUnwrap(URL(string: "https://images.test/offline.png"))
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }

        let image = await ImageLoader.load(url)

        XCTAssertNil(image)
    }

    func testTheImageViewShowsAPlaceholderThenThePicture() async throws {
        useThePretendNetwork()
        defer { stopUsingThePretendNetwork() }
        let url = try XCTUnwrap(URL(string: "https://images.test/view.png"))
        answer(with: makePNGData())
        let imageView = RemoteImageView()

        imageView.setImage(from: nil)
        XCTAssertNotNil(imageView.image, "A placeholder is shown when there is no address")

        imageView.setImage(from: url)
        let loaded = await waitUntil {
            if let cached = ImageLoader.cachedImage(for: url) {
                return imageView.image === cached
            }
            return false
        }
        XCTAssertTrue(loaded)

        imageView.cancelLoading()
        XCTAssertFalse(imageView.image === ImageLoader.cachedImage(for: url), "Reuse goes back to the placeholder")
    }

    func testAnImageThatIsAlreadyRememberedShowsAtOnce() async throws {
        useThePretendNetwork()
        defer { stopUsingThePretendNetwork() }
        let url = try XCTUnwrap(URL(string: "https://images.test/instant.png"))
        answer(with: makePNGData())
        _ = await ImageLoader.load(url)
        let imageView = RemoteImageView()

        imageView.setImage(from: url)

        XCTAssertTrue(imageView.image === ImageLoader.cachedImage(for: url))
    }
}

import XCTest
import UIKit
@testable import CatalogueApp

@MainActor
final class ProductGridLayoutTests: XCTestCase {

    private func makeCollectionView(width: CGFloat) -> UICollectionView {
        return UICollectionView(
            frame: CGRect(x: 0, y: 0, width: width, height: 800),
            collectionViewLayout: ProductGridLayout.makeLayout()
        )
    }

    func testTwoTilesFitInOneRow() {
        let size = ProductGridLayout.productTileSize(in: makeCollectionView(width: 390))
        let rowWidth = size.width * 2 + Theme.Spacing.medium * 3

        XCTAssertLessThanOrEqual(rowWidth, 390)
        XCTAssertGreaterThan(rowWidth, 388)
    }

    func testTileHeightGrowsWithWidthAndIsNeverNegative() {
        XCTAssertGreaterThan(ProductCell.height(forWidth: 200), ProductCell.height(forWidth: 100))
        XCTAssertEqual(ProductGridLayout.productTileSize(in: makeCollectionView(width: 0)).width, 0)
    }

    func testRowsUseTheWholeWidthMinusTheMargins() {
        let size = ProductGridLayout.fullWidthRowSize(in: makeCollectionView(width: 390), height: 52)

        XCTAssertEqual(size.width, 390 - Theme.Spacing.medium * 2)
        XCTAssertEqual(size.height, 52)
    }

    func testASectionWithNoItemsHasNoHeader() {
        let collectionView = makeCollectionView(width: 390)

        XCTAssertEqual(ProductGridLayout.headerSize(in: collectionView, itemCount: 0), .zero)
        XCTAssertEqual(ProductGridLayout.headerSize(in: collectionView, itemCount: 3).height, ProductGridLayout.headerHeight)
    }
}

import UIKit

// The layout shared by Home, Category and Search: two product tiles per row.
enum ProductGridLayout {
    static let headerHeight: CGFloat = 44

    static func makeLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = Theme.Spacing.medium
        layout.minimumLineSpacing = Theme.Spacing.medium
        layout.sectionInset = UIEdgeInsets(
            top: Theme.Spacing.small,
            left: Theme.Spacing.medium,
            bottom: Theme.Spacing.large,
            right: Theme.Spacing.medium
        )
        return layout
    }

    static func productTileSize(in collectionView: UICollectionView) -> CGSize {
        let sideSpace = Theme.Spacing.medium * 2 + Theme.Spacing.medium
        let width = max(floor((collectionView.bounds.width - sideSpace) / 2), 0)
        return CGSize(width: width, height: ProductCell.height(forWidth: width))
    }

    static func fullWidthRowSize(in collectionView: UICollectionView, height: CGFloat) -> CGSize {
        let width = max(collectionView.bounds.width - Theme.Spacing.medium * 2, 0)
        return CGSize(width: width, height: height)
    }

    // A section with no items gets no header.
    static func headerSize(in collectionView: UICollectionView, itemCount: Int) -> CGSize {
        if itemCount == 0 { return .zero }
        return CGSize(width: collectionView.bounds.width, height: headerHeight)
    }
}

extension UICollectionView {
    func registerCatalogueViews() {
        register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.reuseID)
        register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseID)
        register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseID
        )
    }

    func dequeueProductCell(for indexPath: IndexPath, product: Product) -> UICollectionViewCell {
        guard let cell = dequeueReusableCell(withReuseIdentifier: ProductCell.reuseID, for: indexPath) as? ProductCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: product)
        return cell
    }

    func dequeueCategoryCell(for indexPath: IndexPath, categoryName: String) -> UICollectionViewCell {
        guard let cell = dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseID, for: indexPath) as? CategoryCell else {
            return UICollectionViewCell()
        }
        cell.configure(categoryName: categoryName)
        return cell
    }

    func dequeueSectionHeader(ofKind kind: String, for indexPath: IndexPath, title: String) -> UICollectionReusableView {
        guard let header = dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: SectionHeaderView.reuseID,
            for: indexPath
        ) as? SectionHeaderView else {
            return UICollectionReusableView()
        }
        header.configure(title: title)
        return header
    }
}

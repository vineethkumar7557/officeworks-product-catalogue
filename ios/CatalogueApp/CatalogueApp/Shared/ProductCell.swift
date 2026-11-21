import UIKit

// One product tile: picture, title, rating and price.
final class ProductCell: UICollectionViewCell {
    static let reuseID = "ProductCell"
    private static let imageHeightRatio: CGFloat = 0.8

    private let productImageView = RemoteImageView()
    private let titleLabel = UILabel()
    private let ratingLabel = UILabel()
    private let priceLabel = UILabel()

    // The grid needs the tile height before the tile exists, so we work it out from the fonts.
    static func height(forWidth width: CGFloat) -> CGFloat {
        let spacing = Theme.Spacing.small
        let imageHeight = (width - spacing * 2) * imageHeightRatio
        let textHeight = Theme.Font.body.lineHeight * 2
            + Theme.Font.caption.lineHeight
            + Theme.Font.price.lineHeight
            + Theme.Spacing.extraSmall * 2
        return ceil(spacing * 3 + imageHeight + textHeight)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    func configure(with product: Product) {
        titleLabel.text = product.title
        ratingLabel.text = product.ratingText
        priceLabel.text = product.priceText
        productImageView.setImage(from: product.imageURL)
        accessibilityLabel = "\(product.title), \(product.priceText)"
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        productImageView.cancelLoading()
    }

    private func setUp() {
        contentView.backgroundColor = Theme.Color.cardBackground
        contentView.layer.cornerRadius = Theme.Shape.cornerRadius
        contentView.clipsToBounds = true
        isAccessibilityElement = true
        accessibilityTraits = .button

        productImageView.layer.cornerRadius = Theme.Shape.cornerRadius / 2
        productImageView.clipsToBounds = true

        titleLabel.font = Theme.Font.body
        titleLabel.textColor = Theme.Color.textPrimary
        titleLabel.numberOfLines = 2

        ratingLabel.font = Theme.Font.caption
        ratingLabel.textColor = Theme.Color.star

        priceLabel.font = Theme.Font.price
        priceLabel.textColor = Theme.Color.textPrimary

        let textStack = UIStackView(arrangedSubviews: [titleLabel, ratingLabel, priceLabel])
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = Theme.Spacing.extraSmall

        productImageView.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(productImageView)
        contentView.addSubview(textStack)

        let spacing = Theme.Spacing.small
        NSLayoutConstraint.activate([
            productImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing),
            productImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            productImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            productImageView.heightAnchor.constraint(
                equalTo: productImageView.widthAnchor,
                multiplier: ProductCell.imageHeightRatio
            ),

            textStack.topAnchor.constraint(equalTo: productImageView.bottomAnchor, constant: spacing),
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -spacing),

            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.Font.body.lineHeight * 2)
        ])
    }
}

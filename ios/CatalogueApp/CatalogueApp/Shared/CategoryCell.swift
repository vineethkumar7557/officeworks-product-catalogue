import UIKit

// One row in the "Shop by category" list.
final class CategoryCell: UICollectionViewCell {
    static let reuseID = "CategoryCell"
    static let height: CGFloat = 52

    private let titleLabel = UILabel()
    private let arrowView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    func configure(categoryName: String) {
        titleLabel.text = categoryName.displayName
        accessibilityLabel = categoryName.displayName
    }

    private func setUp() {
        contentView.backgroundColor = Theme.Color.cardBackground
        contentView.layer.cornerRadius = Theme.Shape.cornerRadius
        isAccessibilityElement = true
        accessibilityTraits = .button

        titleLabel.font = Theme.Font.heading
        titleLabel.textColor = Theme.Color.textPrimary

        arrowView.tintColor = Theme.Color.textSecondary
        arrowView.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [titleLabel, arrowView])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Theme.Spacing.small
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Theme.Spacing.medium),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Theme.Spacing.medium),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}

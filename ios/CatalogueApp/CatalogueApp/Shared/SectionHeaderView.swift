import UIKit

// The title above a group of tiles, for example "Top rated".
final class SectionHeaderView: UICollectionReusableView {
    static let reuseID = "SectionHeaderView"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = Theme.Font.title
        titleLabel.textColor = Theme.Color.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .header
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Spacing.medium),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Spacing.medium),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}

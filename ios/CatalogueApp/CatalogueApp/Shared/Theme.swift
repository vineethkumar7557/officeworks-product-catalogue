import UIKit

// The one place for colours, fonts and spacing. A new design means changing this file only.
enum Theme {

    enum Color {
        static let background = UIColor.systemBackground
        static let cardBackground = UIColor.secondarySystemBackground
        static let primary = UIColor.systemBlue
        static let onPrimary = UIColor.white
        static let textPrimary = UIColor.label
        static let textSecondary = UIColor.secondaryLabel
        static let star = UIColor.systemOrange
        static let error = UIColor.systemRed
        static let success = UIColor.systemGreen
    }

    // Fonts follow the user's text size setting (Dynamic Type).
    enum Font {
        static var title: UIFont { UIFont.preferredFont(forTextStyle: .title2) }
        static var heading: UIFont { UIFont.preferredFont(forTextStyle: .headline) }
        static var body: UIFont { UIFont.preferredFont(forTextStyle: .body) }
        static var caption: UIFont { UIFont.preferredFont(forTextStyle: .caption1) }
        static var price: UIFont { UIFont.preferredFont(forTextStyle: .title3) }
    }

    enum Spacing {
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }

    enum Shape {
        static let cornerRadius: CGFloat = 12
    }
}

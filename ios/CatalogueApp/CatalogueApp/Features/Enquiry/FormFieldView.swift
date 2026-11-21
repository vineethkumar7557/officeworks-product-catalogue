import UIKit

// One form row: a title, the input, and a red error text that shows only when needed.
final class FormFieldView: UIView {
    private let errorLabel = UILabel()

    init(title: String, input: UIView) {
        super.init(frame: .zero)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Theme.Font.caption
        titleLabel.textColor = Theme.Color.textSecondary
        titleLabel.adjustsFontForContentSizeCategory = true

        errorLabel.font = Theme.Font.caption
        errorLabel.textColor = Theme.Color.error
        errorLabel.numberOfLines = 0
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.isHidden = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, input, errorLabel])
        stack.axis = .vertical
        stack.spacing = Theme.Spacing.extraSmall
        addSubview(stack)
        stack.pinEdges(to: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    // Pass nil to hide the error.
    func showError(_ text: String?) {
        errorLabel.text = text
        errorLabel.isHidden = (text == nil)
    }
}

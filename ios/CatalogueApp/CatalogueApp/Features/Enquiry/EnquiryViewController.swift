import UIKit

// The enquiry form: name, email, phone (optional) and message.
final class EnquiryViewController: UIViewController {
    private let viewModel: EnquiryViewModel

    private let nameField = UITextField()
    private let emailField = UITextField()
    private let phoneField = UITextField()
    private let messageView = UITextView()
    private let failureLabel = UILabel()
    private let submitButton = UIButton(type: .system)
    private var fieldViews: [EnquiryField: FormFieldView] = [:]

    // The router sets these.
    var onCancel: (() -> Void)?
    var onSubmitted: (() -> Void)?

    init(viewModel: EnquiryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Enquire"
        view.backgroundColor = Theme.Color.background
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.onCancel?() }
        )

        setUpInputs()
        setUpLayout()

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    // MARK: - Set up

    private func setUpInputs() {
        configure(nameField, placeholder: "Your name", keyboard: .default,
                  contentType: .name, capitalization: .words, returnKey: .next)
        configure(emailField, placeholder: "you@example.com", keyboard: .emailAddress,
                  contentType: .emailAddress, capitalization: .none, returnKey: .next)
        configure(phoneField, placeholder: "Optional", keyboard: .phonePad,
                  contentType: .telephoneNumber, capitalization: .none, returnKey: .next)

        messageView.font = Theme.Font.body
        messageView.adjustsFontForContentSizeCategory = true
        messageView.textContainerInset = UIEdgeInsets(top: 10, left: 6, bottom: 10, right: 6)
        messageView.layer.cornerRadius = 8
        messageView.layer.borderWidth = 1
        messageView.layer.borderColor = UIColor.systemGray4.cgColor
        messageView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        messageView.accessibilityLabel = "Message"
    }

    private func configure(
        _ field: UITextField,
        placeholder: String,
        keyboard: UIKeyboardType,
        contentType: UITextContentType,
        capitalization: UITextAutocapitalizationType,
        returnKey: UIReturnKeyType
    ) {
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.font = Theme.Font.body
        field.adjustsFontForContentSizeCategory = true
        field.keyboardType = keyboard
        field.textContentType = contentType
        field.autocapitalizationType = capitalization
        field.autocorrectionType = .no
        field.returnKeyType = returnKey
        field.delegate = self
        field.accessibilityLabel = placeholder
        field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }

    private func setUpLayout() {
        let scrollView = VerticalScrollView(spacing: Theme.Spacing.medium)

        let aboutLabel = UILabel()
        aboutLabel.text = "Enquiry about: \(viewModel.product.title)"
        aboutLabel.font = Theme.Font.heading
        aboutLabel.textColor = Theme.Color.textPrimary
        aboutLabel.numberOfLines = 0
        scrollView.contentStack.addArrangedSubview(aboutLabel)

        let rows: [(EnquiryField, String, UIView)] = [
            (.name, "Name", nameField),
            (.email, "Email", emailField),
            (.phone, "Phone (optional)", phoneField),
            (.message, "Message", messageView)
        ]
        for (field, title, input) in rows {
            let fieldView = FormFieldView(title: title, input: input)
            fieldViews[field] = fieldView
            scrollView.contentStack.addArrangedSubview(fieldView)
        }

        failureLabel.font = Theme.Font.body
        failureLabel.textColor = Theme.Color.error
        failureLabel.numberOfLines = 0
        failureLabel.isHidden = true
        scrollView.contentStack.addArrangedSubview(failureLabel)

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Send enquiry"
        configuration.buttonSize = .large
        submitButton.configuration = configuration
        submitButton.addAction(UIAction { [weak self] _ in self?.submitTapped() }, for: .touchUpInside)
        scrollView.contentStack.addArrangedSubview(submitButton)

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // The keyboard guide moves up with the keyboard, so the fields are never hidden behind it.
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
    }

    // MARK: - Actions

    private func submitTapped() {
        view.endEditing(true)
        let form = EnquiryForm(
            name: nameField.text ?? "",
            email: emailField.text ?? "",
            phone: phoneField.text ?? "",
            message: messageView.text ?? ""
        )
        Task { await self.viewModel.submit(form) }
    }

    // MARK: - Showing the state

    private func render(_ state: EnquiryViewModel.State) {
        switch state {
        case .editing:
            showFieldErrors([:])
            failureLabel.isHidden = true
            setSending(false)
        case .invalid(let errors):
            showFieldErrors(errors)
            failureLabel.isHidden = true
            setSending(false)
            focusFirstField(withErrorIn: errors)
        case .submitting:
            showFieldErrors([:])
            failureLabel.isHidden = true
            setSending(true)
        case .submitted:
            setSending(false)
            onSubmitted?()
        case .failed(let message):
            failureLabel.text = message
            failureLabel.isHidden = false
            setSending(false)
        }
    }

    private func showFieldErrors(_ errors: [EnquiryField: String]) {
        for field in EnquiryField.allCases {
            fieldViews[field]?.showError(errors[field])
        }
    }

    private func focusFirstField(withErrorIn errors: [EnquiryField: String]) {
        guard let first = EnquiryField.allCases.first(where: { errors[$0] != nil }) else { return }
        switch first {
        case .name: nameField.becomeFirstResponder()
        case .email: emailField.becomeFirstResponder()
        case .phone: phoneField.becomeFirstResponder()
        case .message: messageView.becomeFirstResponder()
        }
    }

    // While sending: the button shows a spinner and nothing can be edited or tapped twice.
    private func setSending(_ isSending: Bool) {
        var configuration = submitButton.configuration
        configuration?.showsActivityIndicator = isSending
        configuration?.title = isSending ? "Sending…" : "Send enquiry"
        submitButton.configuration = configuration
        submitButton.isEnabled = !isSending

        nameField.isEnabled = !isSending
        emailField.isEnabled = !isSending
        phoneField.isEnabled = !isSending
        messageView.isEditable = !isSending
    }
}

// MARK: - Return key moves to the next field

extension EnquiryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === nameField {
            emailField.becomeFirstResponder()
        } else if textField === emailField {
            phoneField.becomeFirstResponder()
        } else {
            messageView.becomeFirstResponder()
        }
        return false
    }
}

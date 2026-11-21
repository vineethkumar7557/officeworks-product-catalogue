import UIKit
import Foundation

extension UIView {
    // Every view inside this one (and this one) of the given type.
    func findViews<T: UIView>(ofType type: T.Type) -> [T] {
        var found: [T] = []
        if let match = self as? T {
            found.append(match)
        }
        for subview in subviews {
            found.append(contentsOf: subview.findViews(ofType: type))
        }
        return found
    }

    func findView<T: UIView>(ofType type: T.Type) -> T? {
        return findViews(ofType: type).first
    }

    // True when this view, or any view around it, is hidden.
    var isHiddenInHierarchy: Bool {
        var current: UIView? = self
        while let view = current {
            if view.isHidden { return true }
            current = view.superview
        }
        return false
    }

    func hasVisibleLabel(withText text: String) -> Bool {
        return findViews(ofType: UILabel.self).contains { $0.text == text && !$0.isHiddenInHierarchy }
    }

    func findButton(withTitle title: String) -> UIButton? {
        return findViews(ofType: UIButton.self).first { $0.configuration?.title == title }
    }

    func findTextField(withPlaceholder placeholder: String) -> UITextField? {
        return findViews(ofType: UITextField.self).first { $0.placeholder == placeholder }
    }
}

// Screens load their data in a background task, so tests wait (up to 2 seconds) until a condition is true.
@MainActor
func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() > deadline { return false }
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
    return true
}

// A screen that is big enough to lay itself out, like on a real phone.
@MainActor
func prepare(_ viewController: UIViewController) {
    viewController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
    viewController.loadViewIfNeeded()
}

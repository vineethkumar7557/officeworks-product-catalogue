import UIKit

extension UIView {
    // Makes this view fill another view. Call it after addSubview.
    func pinEdges(to other: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: other.topAnchor),
            bottomAnchor.constraint(equalTo: other.bottomAnchor),
            leadingAnchor.constraint(equalTo: other.leadingAnchor),
            trailingAnchor.constraint(equalTo: other.trailingAnchor)
        ])
    }

    // Makes this view fill a layout guide (for example the safe area).
    func pinEdges(to guide: UILayoutGuide) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: guide.topAnchor),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor)
        ])
    }
}

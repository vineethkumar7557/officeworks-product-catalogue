import UIKit

// An image view that loads its picture from a web address.
final class RemoteImageView: UIImageView {
    private var loadTask: Task<Void, Never>?

    private static var placeholder: UIImage? {
        return UIImage(systemName: "photo")
    }

    // Lets us write RemoteImageView() without a frame.
    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFit
        backgroundColor = .white
        tintColor = Theme.Color.textSecondary
        image = RemoteImageView.placeholder
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    func setImage(from url: URL?) {
        cancelLoading()
        guard let url else { return }

        if let cached = ImageLoader.cachedImage(for: url) {
            image = cached
            return
        }

        loadTask = Task { [weak self] in
            let loaded = await ImageLoader.load(url)
            // If this view was reused for another product meanwhile, the answer is no longer wanted.
            if Task.isCancelled { return }
            self?.image = loaded ?? RemoteImageView.placeholder
        }
    }

    // Stops the download and shows the placeholder again. Cells call this when they are reused.
    func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
        image = RemoteImageView.placeholder
    }
}

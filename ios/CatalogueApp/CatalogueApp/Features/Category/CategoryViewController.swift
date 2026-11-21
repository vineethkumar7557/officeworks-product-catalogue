import UIKit

// A category page: top rated products first, then the others.
final class CategoryViewController: UIViewController {
    private let viewModel: CategoryViewModel
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: ProductGridLayout.makeLayout())
    private let stateView = StateView()
    private var sections: [ProductSection] = []

    var onProductSelected: ((Product) -> Void)?

    init(viewModel: CategoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = Theme.Color.background

        collectionView.backgroundColor = Theme.Color.background
        collectionView.alwaysBounceVertical = true
        collectionView.registerCatalogueViews()
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.pinEdges(to: view)

        stateView.onRetry = { [weak self] in
            self?.loadContent()
        }
        view.addSubview(stateView)
        stateView.pinEdges(to: view.safeAreaLayoutGuide)

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        render(viewModel.state)
        loadContent()
    }

    private func loadContent() {
        Task { await self.viewModel.load() }
    }

    private func render(_ state: ViewState<CategoryProducts>) {
        sections = viewModel.sections
        collectionView.isHidden = sections.isEmpty
        collectionView.reloadData()

        switch state {
        case .loading:
            stateView.showLoading()
        case .loaded:
            stateView.hide()
        case .empty:
            stateView.showMessage("There are no products in this category yet.", canRetry: true)
        case .failed(let message):
            stateView.showMessage(message, canRetry: true)
        }
    }
}

extension CategoryViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].products.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let product = sections[indexPath.section].products[indexPath.item]
        return collectionView.dequeueProductCell(for: indexPath, product: product)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        return collectionView.dequeueSectionHeader(ofKind: kind, for: indexPath, title: sections[indexPath.section].title)
    }
}

extension CategoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onProductSelected?(sections[indexPath.section].products[indexPath.item])
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return ProductGridLayout.productTileSize(in: collectionView)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        return ProductGridLayout.headerSize(in: collectionView, itemCount: sections[section].products.count)
    }
}

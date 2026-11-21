import UIKit

// Shows the products that match what the customer searched for.
final class SearchViewController: UIViewController {
    private let viewModel: SearchViewModel
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: ProductGridLayout.makeLayout())
    private let stateView = StateView()
    private var sections: [ProductSection] = []

    var onProductSelected: ((Product) -> Void)?

    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Search results"
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

    private func render(_ state: ViewState<[Product]>) {
        sections = viewModel.sections
        collectionView.isHidden = sections.isEmpty
        collectionView.reloadData()

        switch state {
        case .loading:
            stateView.showLoading()
        case .loaded:
            stateView.hide()
        case .empty:
            stateView.showMessage(viewModel.emptyMessage, canRetry: false)
        case .failed(let message):
            stateView.showMessage(message, canRetry: true)
        }
    }
}

extension SearchViewController: UICollectionViewDataSource {
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

extension SearchViewController: UICollectionViewDelegateFlowLayout {
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

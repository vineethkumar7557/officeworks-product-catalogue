import UIKit

// The first screen: featured products, the category list and the search bar.
final class HomeViewController: UIViewController {
    private enum Section: Int {
        case featured = 0
        case categories = 1
    }

    private let viewModel: HomeViewModel
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: ProductGridLayout.makeLayout())
    private let stateView = StateView()
    private let searchController = UISearchController(searchResultsController: nil)
    private var content: HomeContent?

    // The router sets these. The screen only reports what the customer tapped.
    var onProductSelected: ((Product) -> Void)?
    var onCategorySelected: ((String) -> Void)?
    var onSearch: ((String) -> Void)?

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used. This app builds its screens in code.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Catalogue"
        view.backgroundColor = Theme.Color.background

        setUpSearch()
        setUpCollectionView()
        setUpStateView()

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        render(viewModel.state)
        loadContent()
    }

    private func loadContent() {
        Task { await self.viewModel.load() }
    }

    // MARK: - Set up

    private func setUpSearch() {
        searchController.searchBar.placeholder = "Search products"
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setUpCollectionView() {
        collectionView.backgroundColor = Theme.Color.background
        collectionView.alwaysBounceVertical = true
        collectionView.registerCatalogueViews()
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.pinEdges(to: view)
    }

    private func setUpStateView() {
        stateView.onRetry = { [weak self] in
            self?.loadContent()
        }
        view.addSubview(stateView)
        stateView.pinEdges(to: view.safeAreaLayoutGuide)
    }

    // MARK: - Showing the state

    private func render(_ state: ViewState<HomeContent>) {
        switch state {
        case .loading:
            show(content: nil)
            stateView.showLoading()
        case .loaded(let loadedContent):
            show(content: loadedContent)
            stateView.hide()
        case .empty:
            show(content: nil)
            stateView.showMessage("There are no products to show right now.", canRetry: true)
        case .failed(let message):
            show(content: nil)
            stateView.showMessage(message, canRetry: true)
        }
    }

    private func show(content newContent: HomeContent?) {
        content = newContent
        collectionView.isHidden = (newContent == nil)
        collectionView.reloadData()
    }

    private func itemCount(in section: Int) -> Int {
        guard let content else { return 0 }
        switch Section(rawValue: section) {
        case .featured: return content.featuredProducts.count
        case .categories: return content.categories.count
        case nil: return 0
        }
    }
}

// MARK: - Data source

extension HomeViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemCount(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let content else { return UICollectionViewCell() }
        switch Section(rawValue: indexPath.section) {
        case .featured:
            return collectionView.dequeueProductCell(for: indexPath, product: content.featuredProducts[indexPath.item])
        case .categories:
            return collectionView.dequeueCategoryCell(for: indexPath, categoryName: content.categories[indexPath.item])
        case nil:
            return UICollectionViewCell()
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let title = (Section(rawValue: indexPath.section) == .featured) ? "Featured products" : "Shop by category"
        return collectionView.dequeueSectionHeader(ofKind: kind, for: indexPath, title: title)
    }
}

// MARK: - Taps and sizes

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let content else { return }
        switch Section(rawValue: indexPath.section) {
        case .featured:
            onProductSelected?(content.featuredProducts[indexPath.item])
        case .categories:
            onCategorySelected?(content.categories[indexPath.item])
        case nil:
            break
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if Section(rawValue: indexPath.section) == .categories {
            return ProductGridLayout.fullWidthRowSize(in: collectionView, height: CategoryCell.height)
        }
        return ProductGridLayout.productTileSize(in: collectionView)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        return ProductGridLayout.headerSize(in: collectionView, itemCount: itemCount(in: section))
    }
}

// MARK: - Search

extension HomeViewController: UISearchBarDelegate {
    // Nothing is searched while typing. Only the Search key on the keyboard starts a search.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let term = SearchTerm.cleaned(searchBar.text) else { return }
        searchBar.resignFirstResponder()
        onSearch?(term)
    }
}

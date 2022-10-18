//
//  ListViewController.swift
//  CollectionViewCompositionalLayoutSample
//
//  Created by yaiwamoto on 02/09/2020.
//  Copyright © 2020 Yasutaka Iwamoto. All rights reserved.
//

import UIKit
import Combine
import SuperEasyLayout

enum Section: CaseIterable, Hashable {
    case today
    case tomorrow
    case none

    var headerTitle: String? {
        switch self {
        case .today: return "本日の工事"
        case .tomorrow: return "翌日以降の工事"
        case .none: return nil
        }
    }

    var columnCount: Int {
        return 5
    }
}

class ListViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var imageView: UIImageView!
    private var viewModel = ListViewModel()

    var dataSource: UICollectionViewDiffableDataSource<Section, ConstructionItem>! = nil

    var snapshot: NSDiffableDataSourceSnapshot<Section, ConstructionItem>!

    private var cancellables: [AnyCancellable] = []

    private var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        let refreshView = UIView()
        refreshView.backgroundColor = .blue
        refreshControl.addSubview(refreshView)
        refreshView.left == refreshControl.left
        refreshView.top == refreshControl.top
        refreshView.right == refreshControl.right
        refreshView.bottom == refreshControl.bottom
        refreshControl.tintColor = .clear
        refreshControl.backgroundColor = .clear

        return refreshControl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        collectionView.register(UINib(nibName: "LabelCell", bundle: nil), forCellWithReuseIdentifier: "labelCell")
        collectionView.register(UINib(nibName: "HeaderView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)

        // collectionViewLayoutを設定(Layoutを方法設定)
        configureHierarchy(hasHeader: true)

        // 細かい描画
        configureDataSource()

        // dataSourceにデータを流し込み
        bindToViewModelOutputs()

        // view -> viewModelへのイベント流し込み
//        bindToInputs()
    }

    @objc func pullToRefresh() {
        viewModel.inputs.pullToRefreshTrigger.send()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
//            self?.refreshControl.endRefreshing()
//        }
    }

    private func bindToViewModelOutputs() {
        viewModel.outputs.constructionList
            .subscribe(on: RunLoop.main)
            .sink(
                receiveValue: { [weak self] constructionList in
                    guard let self = self else { return }
                    self.snapshot.deleteAllItems()

                    let hasHeader = constructionList.map { $0.section }.contains { $0 != .none }

                    constructionList.forEach {
                        self.snapshot.appendSections([$0.section])
                        self.snapshot.appendItems($0.items)
                    }

                    // レイアウト方法を変更
                    self.configureHierarchy(hasHeader: hasHeader)

                    self.dataSource.apply(self.snapshot, animatingDifferences: false)

                    self.refreshControl.endRefreshing()
                }
            )
            .store(in: &cancellables)

        viewModel.outputs.noConstruction
            .subscribe(on: RunLoop.main)
            .sink(receiveValue: { [weak self] noConstruction in
                self?.collectionView.isHidden = noConstruction
                self?.imageView.isHidden = !noConstruction
            })
            .store(in: &cancellables)
    }

    private func bindToInputs() {
        viewModel.inputs.fetchFeaturedBannersTrigger.send()
        viewModel.inputs.changeDataSourceTrigger.send()
    }

    private func configureHierarchy(hasHeader: Bool) {
        collectionView.collectionViewLayout = createMultipleSectionsLayout(hasHeader: hasHeader)
        
    }

    private func createMultipleSectionsLayout(hasHeader: Bool) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int,
                                                            layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(200))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
            group.contentInsets = .init(top: 0, leading: 0, bottom: 10, trailing: 0)

            let section = NSCollectionLayoutSection(group: group)
            if hasHeader {
                section.boundarySupplementaryItems = self.createSupplementaryItemLayout()
            }
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            return section
        }
        
        return layout
    }

    private func createSupplementaryItemLayout() -> [NSCollectionLayoutBoundarySupplementaryItem] {
        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .estimated(44))

        return [NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerFooterSize,
            elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)]
    }

    private func configureDataSource() {
        // dataSourceをviewにbindingするところ
        dataSource = UICollectionViewDiffableDataSource<Section, ConstructionItem>(collectionView: collectionView) {
            (collectionView, indexPath, construction) -> UICollectionViewCell? in
            // itemはindex？
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "labelCell", for: indexPath) as? LabelCell else {
                fatalError("cound not dequeue a labelCell")
            }
            cell.countLabel.text = "\(construction.name)"
            cell.backgroundColor = .orange
            return cell
        }

        dataSource.supplementaryViewProvider = { [weak self] (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in

            guard let self = self else { return nil }
            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView", for: indexPath) as! HeaderView
            headerView.configure(text: section.headerTitle)

            // MEMO: Header・Footerを組み立てるための処理を記載する
            // → indexPath.sectionでセクションを判定 ＆ kindでelementKindSectionHeader(Footer)を判定

            // (例) let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! ExampleCollectionHeaderView
            return headerView
        }

        snapshot = NSDiffableDataSourceSnapshot<Section, ConstructionItem>()
        snapshot.appendSections(Section.allCases)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    @IBAction func dataSourceDidChange(_ sender: Any) {
        viewModel.inputs.changeDataSourceTrigger.send()

    }

    @IBAction func firstSectionDidChange(_ sender: Any) {
        viewModel.inputs.fetchFeaturedBannersTrigger.send()
    }
}


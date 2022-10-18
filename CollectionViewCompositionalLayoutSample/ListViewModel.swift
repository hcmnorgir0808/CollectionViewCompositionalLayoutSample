//
//  ListViewModel.swift
//  CollectionViewCompositionalLayoutSample
//
//  Created by 岩本康孝 on 2022/10/15.
//  Copyright © 2022 Yasutaka Iwamoto. All rights reserved.
//

import Foundation
import Combine

// MARK: - Protocol

// セクション毎のヘッダーとアイテム
struct Construction: Hashable {
    static func == (lhs: Construction, rhs: Construction) -> Bool {
        lhs.uuid == rhs.uuid
    }

    let uuid = UUID().uuidString
    let section: Section
    let items: [ConstructionItem]

}

struct ConstructionItem: Hashable {
    let uuid = UUID().uuidString
    let name: String
}

protocol ListViewModelInputs {
    var fetchFeaturedBannersTrigger: PassthroughSubject<Void, Never> { get }
    var changeDataSourceTrigger: PassthroughSubject<Void, Never> { get }
    var pullToRefreshTrigger: PassthroughSubject<Void, Never> { get }
}

protocol ListViewModelOutputs {
    var constructionList: AnyPublisher<[Construction], Never> { get }
    var noConstruction: AnyPublisher<Bool, Never> { get }
//    var featuredInterviews: AnyPublisher<[FeaturedInterview], Never> { get }
//    var keywords: AnyPublisher<[Keyword], Never> { get }
//    var newArrivals: AnyPublisher<[NewArrival], Never> { get }
//    var articles: AnyPublisher<[Article], Never> { get }
}

protocol ListViewModelType {
    var inputs: ListViewModelInputs { get }
    var outputs: ListViewModelOutputs { get }
}

final class ListViewModel: ListViewModelType, ListViewModelInputs, ListViewModelOutputs {

    // MARK: - MainViewModelType

    var inputs: ListViewModelInputs { return self }
    var outputs: ListViewModelOutputs { return self }

    // MARK: - MainViewModelInputs

    let fetchFeaturedBannersTrigger = PassthroughSubject<Void, Never>()
    let changeDataSourceTrigger = PassthroughSubject<Void, Never>()
    let pullToRefreshTrigger = PassthroughSubject<Void, Never>()

    // MARK: - MainViewModelOutputs

    var constructionList: AnyPublisher<[Construction], Never> {
        return $_constructionList.eraseToAnyPublisher()
    }

    var noConstruction: AnyPublisher<Bool, Never> {
        return $_noConstruction.eraseToAnyPublisher()
    }

//    var confirmList: AnyPublisher<[Construction], Never> {
//        return $_confirmList.eraseToAnyPublisher()
//    }

    private var cancellables: [AnyCancellable] = []

    // MARK: - @Published

    // MEMO: このコードではNSDiffableDataSourceSnapshotの差分更新部分で利用する
    @Published private var _constructionList: [Construction] = []
    @Published private var _noConstruction: Bool = false
//    @Published private var _confirmList: [Construction] = []

    // MARK: - Initializer

    init() {
        // MEMO: InputTriggerとAPIリクエストをするための処理を結合する
        fetchFeaturedBannersTrigger
            .sink(
                receiveValue: { [weak self] in
                    self?.fetchFeaturedBanners()
                }
            )
            .store(in: &cancellables)


        changeDataSourceTrigger
            .sink(receiveValue: { [weak self] in
                self?.dataSourceChange()
            })
            .store(in: &cancellables)

        pullToRefreshTrigger
            .sink(receiveValue: { [weak self] inputs in
                self?.pullToRefresh()
            })
            .store(in: &cancellables)
//        fetchFeaturedInterviewsTrigger
//            .sink(
//                receiveValue: { [weak self] in
//                    self?.fetchFeaturedInterviews()
//                }
//            )
//            .store(in: &cancellables)
//        fetchKeywordsTrigger
//            .sink(
//                receiveValue: { [weak self] in
//                    self?.fetchKeywords()
//                }
//            )
//            .store(in: &cancellables)
//        fetchNewArrivalsTrigger
//            .sink(
//                receiveValue: { [weak self] in
//                    self?.fetchNewArrivals()
//                }
//            )
//            .store(in: &cancellables)
//        fetchArticlesTrigger
//            .sink(
//                receiveValue: { [weak self] in
//                    self?.fetchArticles()
//                }
//            )
//            .store(in: &cancellables)
    }

    // MARK: - deinit

    deinit {
        cancellables.forEach { $0.cancel() }
    }

    func section(index: Int) -> Section? {
//        print(_constructionList.values)

        _constructionList[safe: index]?.section
      //  return self._constructionList[safe: index]?.section
    }


    // MARK: - Privete Function

    private func fetchFeaturedBanners() {
        self._constructionList = [
            .init(
                section: .today,
                items: [
                    .init(name: "配水管付設工事"),
                    .init(name: "屋根工事")
                ]
            ),
            .init(
                section: .tomorrow,
                items: [
                    .init(name: "水道管工事"),
                    .init(name: "下水管工事")
                ]
            )
        ]
        self._noConstruction = false
    }

    private func dataSourceChange() {
        self._constructionList = []
        self._noConstruction = true
    }

    private func pullToRefresh() {
        self._constructionList.append(.init(section: .tomorrow, items: [
            .init(name: "明日の工事")
        ]))
    }

//        api.getFeaturedBanners()
//            .receive(on: RunLoop.main)
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    // MEMO: 値取得成功時（※本当は厳密にエラーハンドリングする必要がある）
//                    case .finished:
//                        print("finished fetchFeaturedBanners(): \(completion)")
//                    // MEMO: エラー時（※本当は厳密にエラーハンドリングする必要がある）
//                    case .failure(let error):
//                        print("error fetchFeaturedBanners(): \(error.localizedDescription)")
//                    }
//                },
//                receiveValue: { [weak self] hashableObjects in
//                    print(hashableObjects)
//                    self?._featuredBanners = hashableObjects
//                }
//            )
//            .store(in: &cancellables)
//
//    private func fetchFeaturedInterviews() {
//        api.getFeaturedInterviews()
//            .receive(on: RunLoop.main)
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    // MEMO: 値取得成功時（※本当は厳密にエラーハンドリングする必要がある）
//                    case .finished:
//                        print("finished fetchFeaturedInterviews(): \(completion)")
//                    // MEMO: エラー時（※本当は厳密にエラーハンドリングする必要がある）
//                    case .failure(let error):
//                        print("error fetchFeaturedInterviews(): \(error.localizedDescription)")
//                    }
//                },
//                receiveValue: { [weak self] hashableObjects in
//                    print(hashableObjects)
//                    self?._featuredInterviews = hashableObjects
//                }
//            )
//            .store(in: &cancellables)
//    }
//
//    private func fetchKeywords() {
//        api.getKeywords()
//            .receive(on: RunLoop.main)
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    // MEMO: 値取得成功時（※本当は厳密にエラーハンドリングする必要がある）
//                    case .finished:
//                        print("finished fetchKeywords(): \(completion)")
//                    // MEMO: エラー時（※本当は厳密にエラーハンドリングする必要がある）
//                    case .failure(let error):
//                        print("error fetchKeywords(): \(error.localizedDescription)")
//                    }
//                },
//                receiveValue: { [weak self] hashableObjects in
//                    print(hashableObjects)
//                    self?._keywords = hashableObjects
//                }
//            )
//            .store(in: &cancellables)
//    }
//
//    private func fetchNewArrivals() {
//        api.getNewArrivals()
//            .receive(on: RunLoop.main)
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    // MEMO: 値取得成功時（※本当は厳密にエラーハンドリングする必要がある）
//                    case .finished:
//                        print("finished fetchNewArrivals(): \(completion)")
//                    // MEMO: エラー時（※本当は厳密にエラーハンドリングする必要がある）
//                    case .failure(let error):
//                        print("error fetchNewArrivals(): \(error.localizedDescription)")
//                    }
//                },
//                receiveValue: { [weak self] hashableObjects in
//                    print(hashableObjects)
//                    self?._newArrivals = hashableObjects
//                }
//            )
//            .store(in: &cancellables)
//    }
//
//    private func fetchArticles() {
//        api.getArticles()
//            .receive(on: RunLoop.main)
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    // MEMO: 値取得成功時（※本当は厳密にエラーハンドリングする必要がある）
//                    case .finished:
//                        print("finished getArticles(): \(completion)")
//                    // MEMO: エラー時（※本当は厳密にエラーハンドリングする必要がある）
//                    case .failure(let error):
//                        print("error getArticles(): \(error.localizedDescription)")
//                    }
//                },
//                receiveValue: { [weak self] hashableObjects in
//                    print(hashableObjects)
//                    self?._articles = hashableObjects
//                }
//            )
//            .store(in: &cancellables)
//    }
}

extension Array {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

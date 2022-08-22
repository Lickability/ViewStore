//
//  PhotoListViewStore.swift
//  ViewStore
//
//  Created by Twig on 2/24/22.
//

import Foundation
import Provider
import Combine
import SwiftUI
import CasePaths

/// Coordinates state for use in `PhotoListView`
final class PhotoListViewStore: ViewStore {

    // MARK: - ViewStore

    struct ViewState {
        enum Status {
            case error(Error)
            case loading
            case content([Photo])
        }

        fileprivate static let defaultNavigationTitle = LocalizedStringKey("Photos")
        fileprivate static let initial = ViewState(status: .loading, showsPhotoCount: false, navigationTitle: defaultNavigationTitle, searchText: "")

        let status: Status
        let showsPhotoCount: Bool
        let navigationTitle: LocalizedStringKey
        fileprivate let searchText: String
    }

    enum Action {
        case toggleShowsPhotoCount(Bool)
        case search(String)
    }
    
    @Published private(set) var viewState: ViewState = .initial

    // MARK: - PhotoListViewStore
    
    private let provider: Provider
    private let showsPhotosCountPublisher = PassthroughSubject<Bool, Never>()
    private let searchTextPublisher = PassthroughSubject<String, Never>()

    var showsPhotoCount: Binding<Bool> {
//
//        return Binding<Bool> {
//            self.viewState.showsPhotoCount
//        } set: { newValue in
//            self.send(.toggleShowsPhotoCount(newValue))
//        }
//
//        Note: This 👇 is just a shorthand version of this 👆
        makeBinding(viewStateKeyPath: \.showsPhotoCount, actionCasePath: /Action.toggleShowsPhotoCount)
    }

    var searchText: Binding<String> {
        makeBinding(viewStateKeyPath: \.searchText, actionCasePath: /Action.search)
    }

    /// Creates a new `PhotoListViewStore`
    /// - Parameters:
    ///   - provider: The provider responsible for fetching photos.
    ///   - scheduler: Determines how state updates are scheduled to be delivered in the view store. Defaults to `default`, which asynchronously schedules updates on the main queue.
    init(provider: Provider, scheduler: MainQueueScheduler = .init(type: .default)) {
        self.provider = provider
        let showsPhotosCountPublisher = self.showsPhotosCountPublisher.prepend(ViewState.initial.showsPhotoCount)
        let photoPublisher = provider.providePhotos().prepend([])
        let searchTextPublisher = self.searchTextPublisher.debounce(for: .seconds(1), scheduler: scheduler).prepend(ViewState.initial.searchText)
        photoPublisher
            .combineLatest(showsPhotosCountPublisher, searchTextPublisher)
            .map { (result: Result<[Photo], ProviderError>, showsPhotosCount: Bool, searchText: String) in
                switch result {
                case let .success(photos):
                    let filteredPhotos = photos.filter(searchText: searchText)
                    let navigationTitle = showsPhotosCount ? LocalizedStringKey("Photos \(filteredPhotos.count)") : ViewState.defaultNavigationTitle
                    return ViewState(status: .content(filteredPhotos), showsPhotoCount: showsPhotosCount, navigationTitle: navigationTitle, searchText: searchText)
                case let .failure(error):
                    return ViewState(status: .error(error), showsPhotoCount: false, navigationTitle: ViewState.defaultNavigationTitle, searchText: searchText)
                }
            }
            .receive(on: scheduler)
            .assign(to: &$viewState)
    }

    // MARK: - ViewStore

    func send(_ action: Action) {
        switch action {
        case let .toggleShowsPhotoCount(showsPhotoCount):
            showsPhotosCountPublisher.send(showsPhotoCount)
        case let .search(searchText):
            searchTextPublisher.send(searchText)
        }
    }
}

private extension Provider {
    func providePhotos() -> AnyPublisher<Result<[Photo], ProviderError>, Never> {
        provideItems(request: APIRequest.photos, decoder: JSONDecoder(), providerBehaviors: [], requestBehaviors: [], allowExpiredItems: true)
            .map { (photos: [Photo]) in
                .success(photos)
            }
            .catch { error in
                Just(.failure(error))
            }
            .eraseToAnyPublisher()
    }
}

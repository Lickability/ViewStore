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

struct PSA {
    let title: String
}

final class PSAViewStore: ViewStore {
    
    static let initial = ViewState(psa: .init(title: "Intial"))
    
    @Published var viewState: ViewState = PSAViewStore.initial
    
    private let psaSubject = PassthroughSubject<PSA, Never>()

    
    init() {
        psaSubject
            .map(ViewState.init)
            .assign(to: &$viewState)
    }
    
    struct ViewState {
        let psa: PSA
    }
    
    enum Action {
        case updatePSA(PSA)
    }
    
    func send(_ action: Action) {
        switch action {
        case .updatePSA(let psa):
            psaSubject.send(psa)
        }
    }
    
}


typealias PhotoListViewStoreType = ViewStore<PhotoListViewStore.ViewState, PhotoListViewStore.Action>

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
        fileprivate static let initial = ViewState()

        let status: Status
        let showsPhotoCount: Bool
        let navigationTitle: LocalizedStringKey
        let searchText: String
        let psaState: PSAViewStore.ViewState
        
        init(status: PhotoListViewStore.ViewState.Status = .loading,
             showsPhotoCount: Bool = false,
             navigationTitle: LocalizedStringKey = ViewState.defaultNavigationTitle,
             searchText: String = "",
             psaState: PSAViewStore.ViewState = .init(psa: .init(title: "Initial"))) {
            self.status = status
            self.showsPhotoCount = showsPhotoCount
            self.navigationTitle = navigationTitle
            self.searchText = searchText
            self.psaState = psaState
        }
    }

    enum Action {
        case toggleShowsPhotoCount(Bool)
        case search(String)
        
        case psaAction(PSAViewStore.Action)
    }
    
    @Published private(set) var viewState: ViewState = .initial

    // MARK: - PhotoListViewStore
    
    private let provider: Provider
    private let showsPhotosCountPublisher = PassthroughSubject<Bool, Never>()
    private let searchTextPublisher = PassthroughSubject<String, Never>()
    
    private let psaViewStore = PSAViewStore()

    /// Creates a new `PhotoListViewStore`
    /// - Parameters:
    ///   - provider: The provider responsible for fetching photos.
    ///   - scheduler: Determines how state updates are scheduled to be delivered in the view store. Defaults to `default`, which asynchronously schedules updates on the main queue.
    init(provider: Provider, scheduler: MainQueueScheduler = .init(type: .default)) {
        self.provider = provider
        let showsPhotosCountPublisher = self.showsPhotosCountPublisher.prepend(ViewState.initial.showsPhotoCount)
        let photoPublisher = provider.providePhotos().prepend([])
        let searchTextUIPublisher =  self.searchTextPublisher.prepend(ViewState.initial.searchText)
        let searchTextPublisher = searchTextUIPublisher.throttle(for: 1, scheduler: scheduler, latest: true)

        photoPublisher
            .combineLatest(showsPhotosCountPublisher, searchTextPublisher, searchTextUIPublisher, psaViewStore.$viewState)
            .map { (result: Result<[Photo], ProviderError>, showsPhotosCount: Bool, searchText: String, searchTextUI: String, psaViewState) in
                switch result {
                case let .success(photos):
                    let filteredPhotos = photos.filter(searchText: searchText)
                    let navigationTitle = showsPhotosCount ? LocalizedStringKey("Photos \(filteredPhotos.count)") : ViewState.defaultNavigationTitle
                    return ViewState(status: .content(filteredPhotos), showsPhotoCount: showsPhotosCount, navigationTitle: navigationTitle, searchText: searchTextUI, psaState: psaViewState)
                case let .failure(error):
                    return ViewState(status: .error(error), showsPhotoCount: false, navigationTitle: ViewState.defaultNavigationTitle, searchText: searchTextUI, psaState: psaViewState)
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
        case let .psaAction(action):
            psaViewStore.send(action)
        }
    }
}

extension PhotoListViewStoreType {
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

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

typealias PhotoListViewStoreType = Store<PhotoListViewStore.State, PhotoListViewStore.Action>

/// Coordinates state for use in `PhotoListView`
final class PhotoListViewStore: Store {

    // MARK: - Store

    struct State: Sendable {
        
        /// Status defines the current status of the photo list view
        enum Status {
            /// Error state with associated Error object
            case error(Error)
            
            /// Loading state while fetching photos
            case loading
            
            /// Content state with an array of Photo objects
            case content([Photo])
        }
        
        /// Default navigation title for the view
        nonisolated(unsafe) fileprivate static let defaultNavigationTitle = LocalizedStringKey("Photos")
        
        /// Initial state of the photo list view store
        fileprivate static let initial = State()
        
        /// Current status of the photo list view
        let status: Status
        
        /// Determines if the photo count should be displayed
        let showsPhotoCount: Bool
        
        /// Navigation title for the view
        nonisolated(unsafe) let navigationTitle: LocalizedStringKey
        
        /// Search text entered by the user
        let searchText: String
        
        /// State of the nested banner data store
        let bannerState: BannerDataStore.State
        
        /// Determines whether to show a view that allows the user to enter new text for the banner
        let showUpdateView: Bool
        
        /// Computed property to get the source of truth `banner` from `bannerState`
        var banner: Banner {
            return bannerState.banner
        }

        /// Initializes a new State instance with provided or default values
        /// - Parameters:
        ///   - status: The current status of the photo list view
        ///   - showsPhotoCount: Determines if the photo count should be displayed
        ///   - navigationTitle: Navigation title for the view
        ///   - searchText: Search text entered by the user
        ///   - bannerState: State of the banner data store
        ///   - showUpdateView: Determines if the update view should be shown
        init(status: PhotoListViewStore.State.Status = .loading,
             showsPhotoCount: Bool = false,
             navigationTitle: LocalizedStringKey = State.defaultNavigationTitle,
             searchText: String = "",
             bannerState: BannerDataStore.State = .initial,
             showUpdateView: Bool = false) {
            self.status = status
            self.showsPhotoCount = showsPhotoCount
            self.navigationTitle = navigationTitle
            self.searchText = searchText
            self.bannerState = bannerState
            self.showUpdateView = showUpdateView
        }
    }
    
    enum Action {
        /// Toggle the display of photo count
        case toggleShowsPhotoCount(Bool)
        
        /// Perform search with given query string
        case search(String)
        
        /// Toggle the display of the update view
        case showUpdateView(Bool)
        
        /// Nested banner action cases
        case bannerAction(BannerDataStore.Action)
    }
    
    @Published private(set) var state: State = .initial
    
    var publishedState: AnyPublisher<State, Never> {
        $state.eraseToAnyPublisher()
    }

    // MARK: - PhotoListViewStore
    
    private let provider: Provider
    private let showsPhotosCountPublisher = PassthroughSubject<Bool, Never>()
    private let showUpdateViewPublisher = PassthroughSubject<Bool, Never>()
    private let searchTextPublisher = PassthroughSubject<String, Never>()
    
    private let bannerDataStore = BannerDataStore()

    /// Creates a new `PhotoListViewStore`
    /// - Parameters:
    ///   - provider: The provider responsible for fetching photos.
    ///   - scheduler: Determines how state updates are scheduled to be delivered in the store. Defaults to `default`, which asynchronously schedules updates on the main queue.
    init(provider: Provider, scheduler: MainQueueScheduler = .init(type: .default)) {
        self.provider = provider
        let showsPhotosCountPublisher = self.showsPhotosCountPublisher.prepend(State.initial.showsPhotoCount)
        let photoPublisher = provider.providePhotos().prepend([])
        let searchTextUIPublisher =  self.searchTextPublisher.prepend(State.initial.searchText)
        let searchTextPublisher = searchTextUIPublisher.throttle(for: 1, scheduler: scheduler, latest: true)
        

        photoPublisher
            .combineLatest(showsPhotosCountPublisher, searchTextPublisher, searchTextUIPublisher, bannerDataStore.$state, showUpdateViewPublisher.prepend(false))
            .map { (result: Result<[Photo], ProviderError>, showsPhotosCount: Bool, searchText: String, searchTextUI: String, bannerViewState, showUpdateView) in
                switch result {
                case let .success(photos):
                    let filteredPhotos = photos.filter(searchText: searchText)
                    let navigationTitle = showsPhotosCount ? LocalizedStringKey("Photos \(filteredPhotos.count)") : State.defaultNavigationTitle
                    return State(status: .content(filteredPhotos), showsPhotoCount: showsPhotosCount, navigationTitle: navigationTitle, searchText: searchTextUI, bannerState: bannerViewState, showUpdateView: showUpdateView)
                case let .failure(error):
                    return State(status: .error(error), showsPhotoCount: false, navigationTitle: State.defaultNavigationTitle, searchText: searchTextUI, bannerState: bannerViewState, showUpdateView: showUpdateView)
                }
            }
            .receive(on: scheduler)
            .assign(to: &$state)
    }

    // MARK: - Store

    func send(_ action: Action) {
        switch action {
        case let .toggleShowsPhotoCount(showsPhotoCount):
            showsPhotosCountPublisher.send(showsPhotoCount)
        case let .search(searchText):
            searchTextPublisher.send(searchText)
        case let .bannerAction(action):
            bannerDataStore.send(action)
        case let .showUpdateView(showUpdateView):
            showUpdateViewPublisher.send(showUpdateView)
        }
    }
}

extension PhotoListViewStoreType {
    
    /// Computed property that provides a scoped `BannerDataStoreType` instance
    var bannerDataStore: any BannerDataStoreType {
        return scoped(stateKeyPath: \.bannerState, actionCasePath: /Action.bannerAction)
    }
    
    /// Computed property that creates a binding for the `showUpdateView` state
    @MainActor
    var showUpdateView: Binding<Bool> {
        makeBinding(stateKeyPath: \.showUpdateView, actionCasePath: /PhotoListViewStore.Action.showUpdateView)
    }
    
    /// Computed property that creates a binding for the `showsPhotoCount` state
    @MainActor
    var showsPhotoCount: Binding<Bool> {
//
//        return Binding<Bool> {
//            self.state.showsPhotoCount
//        } set: { newValue in
//            self.send(.toggleShowsPhotoCount(newValue))
//        }
//
//        Note: This 👇 is just a shorthand version of this 👆
        makeBinding(stateKeyPath: \.showsPhotoCount, actionCasePath: /Action.toggleShowsPhotoCount)
    }

    /// Computed property that creates a binding for the `searchText` state
    @MainActor
    var searchText: Binding<String> {
        makeBinding(stateKeyPath: \.searchText, actionCasePath: /Action.search)
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

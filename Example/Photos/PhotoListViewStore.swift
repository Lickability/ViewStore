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

fileprivate var subjectDictionary = [String: any Subject]()

@propertyWrapper struct ViewStateProperty<Value> {
    var wrappedValue: Value

    var projectedValue: ViewStateProperty<Value> { return self }

    let subject: PassthroughSubject<Value, Never>
    
    var prependedPublisher: AnyPublisher<Value, Never> {
        return subject.prepend(wrappedValue).eraseToAnyPublisher()
    }

    init(wrappedValue: Value, id: String) {
        self.wrappedValue = wrappedValue
        
        if let subject = subjectDictionary[id] as? PassthroughSubject<Value, Never> {
            self.subject = subject
        } else {
            let subject = PassthroughSubject<Value, Never>()
            subjectDictionary[id] = subject
            self.subject = subject
        }
    }
}

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
        
        private(set) var status: Status = .loading
        
        @ViewStateProperty(id: "showsPhotoCount")
        private(set) var showsPhotoCount: Bool = false
    
        private(set) var navigationTitle: LocalizedStringKey = defaultNavigationTitle
        
        @ViewStateProperty(id: "searchText")
        fileprivate(set) var searchText: String = ""
    }

    enum Action {
        case toggleShowsPhotoCount(Bool)
        case search(String)
    }
    
    @Published private(set) var viewState = ViewState()

    // MARK: - PhotoListViewStore
    
    private let provider: Provider
    private var cancellables = Set<AnyCancellable>()

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
        
        let photoPublisher = provider.providePhotos().prepend([])
        let searchTextPublisher = viewState.$searchText.prependedPublisher//.debounce(for: .seconds(1), scheduler: scheduler)
        
        photoPublisher
            .combineLatest(viewState.$showsPhotoCount.prependedPublisher, searchTextPublisher)
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
            viewState.$showsPhotoCount.subject.send(showsPhotoCount)
        case let .search(searchText):
            viewState.$searchText.subject.send(searchText)
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

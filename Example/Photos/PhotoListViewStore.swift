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
import AsyncAlgorithms

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
    init(provider: Provider, scheduler: MainQueueScheduler = .init(type: .default), clock: some Clock<Duration> = ContinuousClock()) {
        self.provider = provider
        
        let showsPhotosCountPublisher = self.showsPhotosCountPublisher.prepend(ViewState.initial.showsPhotoCount)
        let photoPublisher = provider.providePhotos().prepend([])
        let searchTextPublisher = self.searchTextPublisher.debounce(for: .seconds(1), scheduler: scheduler).prepend(ViewState.initial.searchText)
        
        let searchUITextPublisher = self.searchTextPublisher.prepend("")
        
        combineLatest(showsPhotosCountPublisher.values, photoPublisher.values, searchTextPublisher.values, searchUITextPublisher.values)
            
        
        photoPublisher
            .combineLatest(showsPhotosCountPublisher, searchTextPublisher, self.searchTextPublisher.prepend(""))
            .map { (result: Result<[Photo], ProviderError>, showsPhotosCount: Bool, searchText: String, searchTextForUI: String) in
                switch result {
                case let .success(photos):
                    let filteredPhotos = photos.filter(searchText: searchText)
                    let navigationTitle = showsPhotosCount ? LocalizedStringKey("Photos \(filteredPhotos.count)") : ViewState.defaultNavigationTitle
                    return ViewState(status: .content(filteredPhotos), showsPhotoCount: showsPhotosCount, navigationTitle: navigationTitle, searchText: searchTextForUI)
                case let .failure(error):
                    return ViewState(status: .error(error), showsPhotoCount: false, navigationTitle: ViewState.defaultNavigationTitle, searchText: searchTextForUI)
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



public func combineLatest<Base1: AsyncSequence, Base2: AsyncSequence, Base3: AsyncSequence, Base4: AsyncSequence>(_ base1: Base1, _ base2: Base2, _ base3: Base3, _ base4: Base4) -> AsyncCombineLatest4Sequence<Base1, Base2, Base3, Base4> {
    AsyncCombineLatest4Sequence(base1, base2, base3, base4)
}

/// An `AsyncSequence` that combines the latest values produced from three asynchronous sequences into an asynchronous sequence of tuples.
public struct AsyncCombineLatest4Sequence<Base1: AsyncSequence, Base2: AsyncSequence, Base3: AsyncSequence, Base4: AsyncSequence>: Sendable
where
Base1: Sendable, Base2: Sendable, Base3: Sendable, Base4: Sendable,
Base1.Element: Sendable, Base2.Element: Sendable, Base3.Element: Sendable, Base4.Element: Sendable,
Base1.AsyncIterator: Sendable, Base2.AsyncIterator: Sendable, Base3.AsyncIterator: Sendable, Base4.AsyncIterator: Sendable {
    let base1: Base1
    let base2: Base2
    let base3: Base3
    let base4: Base4
    
    init(_ base1: Base1, _ base2: Base2, _ base3: Base3, _ base4: Base4) {
        self.base1 = base1
        self.base2 = base2
        self.base3 = base3
        self.base4 = base4
    }
}

extension AsyncCombineLatest4Sequence: AsyncSequence {
    public typealias Element = (Base1.Element, Base2.Element, Base3.Element, Base4.Element)
  
  /// The iterator for a `AsyncCombineLatest3Sequence` instance.
  public struct Iterator: AsyncIteratorProtocol, Sendable {
    var iterator: AsyncCombineLatest3Sequence<AsyncCombineLatest2Sequence<Base1, Base2>, Base3, Base4>.Iterator
    
    init(_ base1: Base1.AsyncIterator, _ base2: Base2.AsyncIterator, _ base3: Base3.AsyncIterator, _ base4: Base4.AsyncIterator) {
      iterator = AsyncCombineLatest3Sequence<AsyncCombineLatest2Sequence<Base1, Base2>, Base3, Base4>.Iterator(AsyncCombineLatest2Sequence<Base1, Base2>.Iterator(base1, base2), base3, base4)
    }
    
    public mutating func next() async rethrows -> (Base1.Element, Base2.Element, Base3.Element)? {
      guard let value = try await iterator.next() else {
        return nil
      }
      return (value.0.0, value.0.1, value.1)
    }
  }
  
  public func makeAsyncIterator() -> Iterator {
      Iterator(base1.makeAsyncIterator(), base2.makeAsyncIterator(), base3.makeAsyncIterator(), base4.makeAsyncIterator())
  }
}

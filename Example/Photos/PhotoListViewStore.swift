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
@MainActor
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
    
    let showsPhotosCountChannel = AsyncChannel<Bool>()
    
    let searchTextChannel = AsyncChannel<String>()
    
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
    init(provider: Provider, clock: some Clock<Duration> = ContinuousClock()) {
        self.provider = provider
                
        let photoChannel = provider.providePhotos().prepend(.success([]))

        searchTextChannel.send(element: "")
        showsPhotosCountChannel.send(element: ViewState.initial.showsPhotoCount)
        
        let searchTextChannel = searchTextChannel.broadcast()
        let debounced = searchTextChannel.debounce(for: .seconds(1), clock: clock).prepend("")
        
        let sequence = (combineLatest(showsPhotosCountChannel, photoChannel, debounced, searchTextChannel)
            .map { (showsPhotosCount: Bool, result: Result<[Photo], ProviderError>, searchText: String, searchTextForUI: String) in
                switch result {
                case let .success(photos):
                    let filteredPhotos = photos.filter(searchText: searchText)
                    let navigationTitle = showsPhotosCount ? LocalizedStringKey("Photos \(filteredPhotos.count)") : ViewState.defaultNavigationTitle
                    return ViewState(status: .content(filteredPhotos), showsPhotoCount: showsPhotosCount, navigationTitle: navigationTitle, searchText: searchTextForUI)
                case let .failure(error):
                    return ViewState(status: .error(error), showsPhotoCount: false, navigationTitle: ViewState.defaultNavigationTitle, searchText: searchTextForUI)
                }
        })
        
        Task(priority: .userInitiated) { [weak self] in
            for try await vs in sequence {
                self?.viewState = vs
            }
        }
    }
    
    // MARK: - ViewStore

    func send(_ action: Action) {
        switch action {
        case let .toggleShowsPhotoCount(showsPhotoCount):
            showsPhotosCountChannel.send(element: showsPhotoCount)
        case let .search(searchText):
            searchTextChannel.send(element: searchText)
        }
    }
}

private extension Provider {
    func providePhotos(queue: DispatchQueue = .main) -> AsyncStream<Result<[Photo], ProviderError>> {
        return AsyncStream { continuation in
            provideItems(request: APIRequest.photos, decoder: JSONDecoder(), providerBehaviors: [], requestBehaviors: [], handlerQueue: queue, allowExpiredItems: true) { (result: Result<[Photo], ProviderError>) in
                continuation.yield(result)
                continuation.finish()
            }
        }
    }
}


// We _should_ be able to return something more like `some AsyncSequence<(Base1.Element, Base2.Element, Base3.Element, Base4.Element)>` or the `any` variation here for ease of reading.
// However, `AsyncSequence` does not define a primary associated type yet, so this isn't possible.
// It appears that this is coming in the future, though. https://forums.swift.org/t/missing-type-erasure/61377/4
public func combineLatest<Base1: AsyncSequence,
                            Base2: AsyncSequence,
                            Base3: AsyncSequence,
                          Base4: AsyncSequence>(_ base1: Base1, _ base2: Base2, _ base3: Base3, _ base4: Base4) -> AsyncMapSequence<AsyncCombineLatest2Sequence<AsyncCombineLatest2Sequence<Base1, Base2>, AsyncCombineLatest2Sequence<Base3, Base4>>, (Base1.Element, Base2.Element, Base3.Element, Base4.Element)>{
    
    let first = combineLatest(base1, base2)
    let second = combineLatest(base3, base4)
    
    return combineLatest(first, second).map { element -> (Base1.Element, Base2.Element, Base3.Element, Base4.Element) in
        (element.0.0, element.0.1, element.1.0, element.1.1)
    }
    
}

extension AsyncChannel {
    func send(element: Element, priority: TaskPriority? = .userInitiated) {
        Task(priority: priority) {
            await send(element)
        }
    }
}











// https://github.com/sideeffect-io/AsyncExtensions/blob/main/Sources/Operators/AsyncPrependSequence.swift
public extension AsyncSequence {
  /// Prepends an element to the upstream async sequence.
  ///
  /// ```
  /// let sourceSequence = AsyncLazySequence([1, 2, 3])
  /// let prependSequence = sourceSequence.prepend(0)
  ///
  /// for try await element in prependSequence {
  ///     print(element)
  /// }
  ///
  /// // will print:
  /// // Element is 0
  /// // Element is 1
  /// // Element is 2
  /// // Element is 3
  /// ```
  ///
  /// - Parameter element: The element to prepend.
  /// - Returns: The async sequence prepended with the element.
  func prepend(_ element: @Sendable @autoclosure @escaping () -> Element) -> AsyncPrependSequence<Self> {
    AsyncPrependSequence(self, prependElement: element())
  }
}

public struct AsyncPrependSequence<Base: AsyncSequence>: AsyncSequence {
  public typealias Element = Base.Element
  public typealias AsyncIterator = Iterator

  private var base: Base
  private var prependElement: @Sendable () -> Element

  public init(
    _ base: Base,
    prependElement: @Sendable @autoclosure @escaping () -> Element
  ) {
    self.base = base
    self.prependElement = prependElement
  }

  public func makeAsyncIterator() -> AsyncIterator {
    Iterator(
      base: self.base.makeAsyncIterator(),
      prependElement: self.prependElement
    )
  }

  public struct Iterator: AsyncIteratorProtocol {
    var base: Base.AsyncIterator
    var prependElement: () async throws -> Element
    var hasBeenDelivered = false

    public init(
      base: Base.AsyncIterator,
      prependElement: @escaping () async throws -> Element
    ) {
      self.base = base
      self.prependElement = prependElement
    }

    public mutating func next() async throws -> Element? {
      guard !Task.isCancelled else { return nil }

      if !self.hasBeenDelivered {
        self.hasBeenDelivered = true
        return try await prependElement()
      }

      return try await self.base.next()
    }
  }
}

extension AsyncPrependSequence: Sendable where Base: Sendable {}

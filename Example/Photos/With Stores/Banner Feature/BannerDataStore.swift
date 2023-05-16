//
//  BannerDataStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine

typealias BannerDataStoreType = Store<BannerDataStore.State, BannerDataStore.Action>

/// A `Store` that is responsible for being the source of truth for a `Banner`. This includes updating locally and remotely. Not meant to be used to drive a `View`, but rather meant to be composed into other `Store`s.
final class BannerDataStore: Store {
    
    // MARK: - Store
    
    struct State {
        
        /// Initial state of the banner data store.
        static let initial = State(banner: .init(title: "Banner"), networkState: .notStarted)
        
        /// The source of truth of the banner model object.
        let banner: Banner
        
        /// Networking state of the request to upload a new banner model to the server.
        let networkState: MockBannerNetworkStateController.NetworkState
    }
    
    enum Action {
        /// Changes the local copy of the banner model synchronously.
        case updateBannerLocally(Banner)
        
        /// Sends the banner to the server and then updates the model locally if it was successful.
        case uploadBanner(Banner)
        
        /// Clears the underlying networking state back to `notStarted`.
        case clearNetworkingState
    }
    
    @Published var state: State = BannerDataStore.State.initial
    
    var publishedState: AnyPublisher<State, Never> {
        $state.eraseToAnyPublisher()
    }
    
    // MARK: - BannerDataStore
    
    private let bannerSubject = PassthroughSubject<Banner, Never>()
    private let network: MockBannerNetworkStateController = .init()
    private var cancellables = Set<AnyCancellable>()

    /// Creates a new `BannerDataStore`
    init() {
        
        let networkPublisher = network.publisher.prepend(.notStarted)
        let additionalActions = networkPublisher.compactMap { $0.banner }.map { Action.updateBannerLocally($0) }
        
        bannerSubject
            .prepend(state.banner)
            .combineLatest(network.publisher.prepend(.notStarted))
            .map { banner, networkState in
                return State(banner: banner, networkState: networkState)
            }
            .assign(to: &$state)

        pipeActions(publisher: additionalActions, storeIn: &cancellables)
    }
    
    // MARK: - Store
    
    func send(_ action: Action) {
        switch action {
        case .updateBannerLocally(let banner):
            bannerSubject.send(banner)
        case .uploadBanner(let banner):
            network.upload(banner: banner)
        case .clearNetworkingState:
            network.reset()
        }
    }
    
}

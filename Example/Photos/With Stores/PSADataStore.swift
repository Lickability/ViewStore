//
//  BannerDataStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine

struct Banner {
    let title: String
}

typealias BannerDataStoreType = Store<BannerDataStore.State, BannerDataStore.Action>

final class BannerDataStore: Store {
    
    struct State {
        static let initial = State(banner: .init(title: "Initial"), networkState: .notStarted)
        
        let banner: Banner
        
        let networkState: Network.NetworkState
    }
    
    enum Action {
        case updateBanner(Banner)
        
        case uploadBanner(Banner)
        case clearNetworkingState
    }
    
    @Published var state: State = BannerDataStore.State.initial
    
    var publishedState: AnyPublisher<State, Never> {
        $state.eraseToAnyPublisher()
    }
    
    private let bannerSubject = PassthroughSubject<Banner, Never>()
    private let network: Network = .init()
    private var cancellables = Set<AnyCancellable>()

    init() {
        
        let networkPublisher = network.publisher.prepend(.notStarted)
        let additionalActions = networkPublisher.compactMap { $0.banner }.map { Action.updateBanner($0) }
        
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
        case .updateBanner(let banner):
            bannerSubject.send(banner)
        case .uploadBanner(let banner):
            network.request(banner: banner)
        case .clearNetworkingState:
            network.reset()
        }
    }
    
}

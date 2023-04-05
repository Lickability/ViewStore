//
//  PSADataStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine

struct PSA {
    let title: String
}

typealias PSADataStoreType = Store<PSADataStore.State, PSADataStore.Action>

final class PSADataStore: Store {
    
    struct State {
        static let initial = State(psa: .init(title: "Initial"), networkState: .notStarted)
        
        let psa: PSA
        
        let networkState: Network.NetworkState
    }
    
    enum Action {
        case updatePSA(PSA)
        
        case uploadPSA(PSA)
        case clearNetworkingState
    }
    
    @Published var state: State = PSADataStore.State.initial
    
    var publishedState: AnyPublisher<State, Never> {
        $state.eraseToAnyPublisher()
    }
    
    private let psaSubject = PassthroughSubject<PSA, Never>()
    private let network: Network = .init()
    private var cancellables = Set<AnyCancellable>()

    init() {
        
        let networkPublisher = network.publisher.prepend(.notStarted)
        let additionalActions = networkPublisher.compactMap { $0.psa }.map { Action.updatePSA($0) }
        
        psaSubject
            .prepend(state.psa)
            .combineLatest(network.publisher.prepend(.notStarted))
            .map { psa, networkState in
                return State(psa: psa, networkState: networkState)
            }
            .assign(to: &$state)

        pipeActions(publisher: additionalActions, storingIn: &cancellables)
    }
    
    // MARK: - Store
    
    func send(_ action: Action) {
        switch action {
        case .updatePSA(let psa):
            psaSubject.send(psa)
        case .uploadPSA(let psa):
            network.request(psa: psa)
        case .clearNetworkingState:
            network.reset()
        }
    }
    
}

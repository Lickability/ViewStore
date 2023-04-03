//
//  PSAViewStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine

final class Network {
    
    enum NetworkState {
        case notStarted
        case inProgress
        case finished(Result<PSA, NSError>)
        
        var psa: PSA? {
            switch self {
            case .inProgress, .notStarted:
                return nil
            case .finished(let result):
                return try? result.get()
            }
        }
        
        var error: Error? {
            switch self {
            case .notStarted, .inProgress:
                return nil
            case .finished(let result):
                do {
                    _ = try result.get()
                    return nil
                }
                catch {
                    return error
                }
            }
        }
    }
    
    var publisher: PassthroughSubject<NetworkState, Never> = .init()
    
    func request(psa: PSA) {
        self.publisher.send(.inProgress)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            //self.publisher.send(.finished(.success(psa)))
            
            self.publisher.send(.finished(.failure(.init())))

        }
    
    }
    
    func reset() {
        self.publisher.send(.notStarted)
    }
    
}

struct PSA {
    let title: String
}

typealias PSAViewStoreType = ViewStore<PSAViewStore.ViewState, PSAViewStore.Action>

final class PSAViewStore: ViewStore {
    
    @Published var viewState: ViewState = PSAViewStore.ViewState.initial
    
    var publishedViewState: AnyPublisher<ViewState, Never> {
        $viewState.eraseToAnyPublisher()
    }
    
    private let psaSubject = PassthroughSubject<PSA, Never>()
    private let network: Network = .init()
    private var cancellables = Set<AnyCancellable>()

    init() {
        
        let networkPublisher = network.publisher.prepend(.notStarted)
        let additionalActions = networkPublisher.compactMap { $0.psa }.map { Action.updatePSA($0) }
        
        psaSubject
            .prepend(viewState.psa)
            .combineLatest(network.publisher.prepend(.notStarted))
            .map { psa, networkState in
                return ViewState(psa: psa, networkState: networkState)
            }
            .assign(to: &$viewState)

        additionalActions
            .sink {
                self.send($0)
            }
            .store(in: &cancellables)
    }
    
    struct ViewState {
        static let initial = ViewState(psa: .init(title: "Intial"), networkState: .notStarted)
        
        let psa: PSA
        
        let networkState: Network.NetworkState
    }
    
    enum Action {
        case updatePSA(PSA)
        
        case submitPSA(PSA)
        case clearNetworkingState
    }
    
    func send(_ action: Action) {
        switch action {
        case .updatePSA(let psa):
            psaSubject.send(psa)
        case .submitPSA(let psa):
            network.request(psa: psa)
        case .clearNetworkingState:
            network.reset()
        }
    }
    
}

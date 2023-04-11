//
//  PSAUpdateViewStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine

typealias PSAUpdateViewStoreType = Store<PSAUpdateViewStore.State, PSAUpdateViewStore.Action>

final class PSAUpdateViewStore: Store {
    
    struct State {
        let psaViewState: PSADataStore.State
        
        let workingCopy: PSA
        
        var dismissable: Bool {
            switch psaViewState.networkState {
            case .notStarted, .finished:
                return true
            case .inProgress:
                return false
            }
        }
        
        var success: Bool {
            switch psaViewState.networkState {
            case .notStarted, .inProgress:
                return false
            case .finished(let result):
                return (try? result.get()) != nil
            }
        }
        
        var error: NSError? {
            switch psaViewState.networkState {
            case .notStarted, .inProgress:
                return nil
            case .finished(let result):
                do {
                    _ = try result.get()
                    return nil
                }
                catch {
                    return error as NSError
                }
            }
        }
    }
    
    enum Action {
        case updateTitle(String)
        
        case dismissError
        
        case submit
    }
    
    @Published var state: State
    var publishedState: AnyPublisher<State, Never> {
        return $state.eraseToAnyPublisher()
    }
    
    private let psaDataStore: any PSADataStoreType
    
    private let newTitlePublisher = PassthroughSubject<String, Never>()
        
    init(psaDataStore: any PSADataStoreType) {
        self.psaDataStore = psaDataStore
        
        state = State(psaViewState: psaDataStore.state, workingCopy: psaDataStore.state.psa)
        
        psaDataStore
            .publishedState
            .combineLatest(newTitlePublisher.map(PSA.init).prepend(state.workingCopy))
            .map { psaState, workingCopy in
                State(psaViewState: psaState, workingCopy: workingCopy)
            }
            .assign(to: &$state)
    }
    
    // MARK: - Store
    
    func send(_ action: Action) {
        switch action {
        case .updateTitle(let title):
            newTitlePublisher.send(title)
        case .submit:
            psaDataStore.send(.uploadPSA(state.workingCopy))
        case .dismissError:
            psaDataStore.send(.clearNetworkingState)
        }
    }
    
}

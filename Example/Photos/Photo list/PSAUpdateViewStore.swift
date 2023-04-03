//
//  PSAUpdateViewStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine

typealias PSAUpdateViewStoreType = ViewStore<PSAUpdateViewStore.ViewState, PSAUpdateViewStore.Action>

final class PSAUpdateViewStore: ViewStore {
    
    @Published var viewState: ViewState
    var publishedViewState: AnyPublisher<ViewState, Never> {
        return $viewState.eraseToAnyPublisher()
    }
    
    private let psaDataStore: any PSADataStoreType
    
    private let newTitlePublisher = PassthroughSubject<String, Never>()
        
    init(psaDataStore: any PSADataStoreType) {
        self.psaDataStore = psaDataStore
        
        viewState = ViewState(psaViewState: psaDataStore.viewState, workingCopy: psaDataStore.viewState.psa)
        
        psaDataStore
            .publishedViewState
            .combineLatest(newTitlePublisher.map(PSA.init).prepend(viewState.workingCopy))
            .map { psaState, workingCopy in
                ViewState(psaViewState: psaState, workingCopy: workingCopy)
            }
            .assign(to: &$viewState)
    }
    
    struct ViewState {
        let psaViewState: PSADataStore.ViewState
        
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
                    return NSError(domain: "3243432", code: 33243)
                }
            }
        }
    }
    
    enum Action {
        case updateTitle(String)
        
        case dismissError
        
        case submit
    }
    
    func send(_ action: Action) {
        switch action {
        case .updateTitle(let title):
            newTitlePublisher.send(title)
        case .submit:
            psaDataStore.send(.uploadPSA(viewState.workingCopy))
        case .dismissError:
            psaDataStore.send(.clearNetworkingState)
        }
    }
    
}

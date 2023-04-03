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
    
    private let psaViewStore: any PSAViewStoreType
    
    private let newTitlePublisher = PassthroughSubject<String, Never>()
        
    init(psaViewStore: any PSAViewStoreType) {
        self.psaViewStore = psaViewStore
        
        viewState = ViewState(psaViewState: psaViewStore.viewState, workingCopy: psaViewStore.viewState.psa)
        
        psaViewStore
            .publishedViewState
            .combineLatest(newTitlePublisher.map(PSA.init).prepend(viewState.workingCopy))
            .map { psaState, workingCopy in
                ViewState(psaViewState: psaState, workingCopy: workingCopy)
            }
            .assign(to: &$viewState)
    }
    
    struct ViewState {
        let psaViewState: PSAViewStore.ViewState
        
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
        
        var error: Error? {
            switch psaViewState.networkState {
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
    
    enum Action {
        case updateTitle(String)
        
        case submit
    }
    
    func send(_ action: Action) {
        switch action {
        case .updateTitle(let title):
            newTitlePublisher.send(title)
        case .submit:
            psaViewStore.send(.submitPSA(viewState.workingCopy))
        }
    }
    
}

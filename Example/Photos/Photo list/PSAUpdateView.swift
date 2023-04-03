//
//  PSAUpdateView.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import SwiftUI
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

struct PSAUpdateView<Store: PSAUpdateViewStoreType>: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var store: Store

    init(store: @autoclosure @escaping () -> Store) {
        self._store = StateObject(wrappedValue: store())
    }

    var body: some View {
        VStack {
            TextField("", text: Binding(get: { store.viewState.workingCopy.title }, set: { string in
                store.send(.updateTitle(string))
            }))
            
            Spacer()
            
            Button {
                store.send(.submit)
            } label: {
                Text("Submit")
            }
            .disabled(!store.viewState.dismissable)
            

        }
    }
}

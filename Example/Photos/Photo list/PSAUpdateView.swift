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

final class Network {
    
    enum NetworkState {
        case notStarted
        case inProgress
        case finished(Result<PSA, Error>)
    }
    
    var publisher: PassthroughSubject<NetworkState, Never> = .init()
    
    func request(psa: PSA) {
        self.publisher.send(.inProgress)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.publisher.send(.finished(.success(psa)))
        }
    
    }
    
}

final class PSAUpdateViewStore: ViewStore {
    
    @Published var viewState: ViewState
    var publishedViewState: AnyPublisher<ViewState, Never> {
        return $viewState.eraseToAnyPublisher()
    }
    
    private let psaViewStore: any PSAViewStoreType
    
    private let newTitlePublisher = PassthroughSubject<String, Never>()
    
    private let network = Network()
    
    init(psaViewStore: any PSAViewStoreType) {
        self.psaViewStore = psaViewStore
        
        viewState = ViewState(psaViewState: psaViewStore.viewState, workingCopy: psaViewStore.viewState.psa, networkState: .notStarted)
        
        psaViewStore
            .publishedViewState
            .combineLatest(newTitlePublisher.map(PSA.init).prepend(viewState.workingCopy), network.publisher.prepend(.notStarted))
            .map { psaState, workingCopy, networkState in
                ViewState(psaViewState: psaState, workingCopy: workingCopy, networkState: networkState)
            }
            .assign(to: &$viewState)
    }
    
    struct ViewState {
        let psaViewState: PSAViewStore.ViewState
        
        let workingCopy: PSA
        
        let networkState: Network.NetworkState
       
        var allowsDismiss: Bool {
            switch networkState {
            case .inProgress:
                return false
            case .notStarted, .finished:
                return true
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
            psaViewStore.send(.updatePSA(viewState.workingCopy))
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
            .disabled(!store.viewState.allowsDismiss)
            

        }
    }
}

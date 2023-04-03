//
//  ScopedViewStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine

final class ScopedViewStore<ViewState, Action>: ViewStore {
    @Published var viewState: ViewState
    
    var publishedViewState: AnyPublisher<ViewState, Never> {
        return $viewState.eraseToAnyPublisher()
    }

    private let action: (Action) -> Void
    
    init(initial: ViewState, viewStatePub: AnyPublisher<ViewState, Never>, action: @escaping (Action) -> Void) {
        viewState = initial
        self.action = action
        viewStatePub.assign(to: &$viewState)
    }

    func send(_ action: Action) {
        self.action(action)
    }

}

//
//  ScopedViewStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine
import CasePaths

public final class ScopedViewStore<ViewState, Action>: ViewStore {
    @Published public var viewState: ViewState
    
    public var publishedViewState: AnyPublisher<ViewState, Never> {
        return $viewState.eraseToAnyPublisher()
    }

    private let action: (Action) -> Void
    
    public init(initial: ViewState, viewStatePub: some Publisher<ViewState, Never>, action: @escaping (Action) -> Void) {
        viewState = initial
        self.action = action
        viewStatePub.assign(to: &$viewState)
    }

    public func send(_ action: Action) {
        self.action(action)
    }

}

public extension ViewStore {
    func scoped<Substate, Subaction>(viewStateKeyPath: KeyPath<ViewState, Substate>, actionCasePath: CasePath<Action, Subaction>) -> any ViewStore<Substate, Subaction> {
        return ScopedViewStore(initial: viewState[keyPath: viewStateKeyPath], viewStatePub: publishedViewState.map(viewStateKeyPath), action: { self.send(actionCasePath.embed($0)) })
    }
}


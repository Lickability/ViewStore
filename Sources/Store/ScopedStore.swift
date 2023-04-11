//
//  ScopedStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine
import CasePaths

public final class ScopedStore<State, Action>: Store {
    @Published public var state: State
    
    public var publishedState: AnyPublisher<State, Never> {
        return $state.eraseToAnyPublisher()
    }

    private let action: (Action) -> Void
    
    public init(initial: State, viewStatePub: some Publisher<State, Never>, action: @escaping (Action) -> Void) {
        state = initial
        self.action = action
        viewStatePub.assign(to: &$state)
    }

    public func send(_ action: Action) {
        self.action(action)
    }

}

public extension Store {
    func scoped<Substate, Subaction>(stateKeyPath: KeyPath<State, Substate>, actionCasePath: CasePath<Action, Subaction>) -> any Store<Substate, Subaction> {
        return ScopedStore(initial: state[keyPath: stateKeyPath], viewStatePub: publishedState.map(stateKeyPath), action: { self.send(actionCasePath.embed($0)) })
    }
}


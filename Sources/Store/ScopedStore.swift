//
//  ScopedStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine
import CasePaths

/// A `Store` that's purpose is to allow clients of it to modify a parent's Store and one of it's sub-stores without having direct access to either store.
public final class ScopedStore<State, Action>: Store {
    @Published public var state: State
    
    public var publishedState: AnyPublisher<State, Never> {
        return $state.eraseToAnyPublisher()
    }

    private let action: (Action) -> Void
    
    /// Initializes a new `ScopedStore`
    /// - Parameters:
    ///   - initial: The initial state for this `Store`, likely a copy of whatever the current sub-store's state is now (see the `scoped` function on the `Store` extension for an example)
    ///   - statePub: The publisher that allows this `ScopedStore` to get the lastest copy of the sub-store's state.
    ///   - action: A closure to let you pass actions back to a parent `Store`. (see the `scoped` function on the `Store` extension for an example of embedding these into a "sub-action" of a parent Store to forward to a sub-store)
    public init(initial: State, statePub: some Publisher<State, Never>, action: @escaping (Action) -> Void) {
        state = initial
        self.action = action
        statePub.assign(to: &$state)
    }

    public func send(_ action: Action) {
        self.action(action)
    }
}

public extension Store {
    /// Creates a `ScopedStore` that uses a keypath to a property on the current `Store`s state and a parent `Store`s action that has a subaction as its associated value.
    ///```
    /// typealias ParentStoreType = Store<ParentStore.State, ParentStore.Action>
    ///
    /// final class ParentStore: Store {
    ///     struct State {
    ///         let substate: Substore.State
    ///     }
    ///
    ///     enum Action {
    ///         case subaction(Substore.Action)
    ///     }
    ///
    ///     private let substore = Substore()
    ///
    ///     init() {
    ///         substore.$state
    ///             .map(State.init)
    ///             .assign(&$state)
    ///     }
    ///
    /// }
    ///
    /// extension ParentStoreType {
    ///     var substore: SubstoreType {
    ///         return scoped(stateKeyPath: /.substate, actionCasePath: \Action.subaction)
    ///     }
    /// }
    ///
    /// typealias SubstoreType = Store<Substore.State, Substore.Action>
    /// final class Substore: Store {
    ///     // Store logic and properties to manage some state
    /// }
    ///```
    ///
    /// - Parameters:
    ///   - stateKeyPath: The keypath to the property on the Parent's `State` that is managed by the substore.
    ///   - actionCasePath: The case path to an action on the Parent's `Store` that has the substore's action as the associated value that forwards to the substore.
    /// - Returns: A `Store` that is scoped to the specified state and action.
    func scoped<Substate, Subaction>(stateKeyPath: KeyPath<State, Substate>, actionCasePath: CasePath<Action, Subaction>) -> any Store<Substate, Subaction> {
        return ScopedStore(initial: state[keyPath: stateKeyPath], statePub: publishedState.map(stateKeyPath), action: { self.send(actionCasePath.embed($0)) })
    }
}


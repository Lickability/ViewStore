//
//  Store.swift
//  ViewStore
//
//  Created by Michael Liberatore on 5/16/22.
//

import SwiftUI
import Combine

/// A store is an `ObservableObject` that allows us to separate business and/or view level logic and the rendering of views in a way that is repeatable, prescriptive, flexible, and testable by default.
@MainActor
public protocol Store<State, Action>: ObservableObject {

    /// A container type for state associated with the corresponding domain.
    associatedtype State

    /// Usually represented as an `enum`, `Action` represents any functionality that a store can perform on-demand.
    associatedtype Action

    /// Single source of truth that is used to respresent the current state of the domain.
    var state: State { get }
    
    /// A publisher that publishes each state as it changes.
    var publishedState: AnyPublisher<State, Never> { get }

    /// Single API to perform behaviors or trigger events, usually resulting in updated `state`.
    /// - Parameter action: The action to perform.
    func send(_ action: Action)
}

/// Default implementation that allows stores with no actions to send to ignore this function requirement in the protocol.
public extension Store {
    func send(_ action: Never) {}
}

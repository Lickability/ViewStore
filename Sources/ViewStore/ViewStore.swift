//
//  ViewStore.swift
//  ViewStore
//
//  Created by Michael Liberatore on 5/16/22.
//

import SwiftUI
import Combine

/// A view store is an `ObservableObject` that allows us to separate view-specific logic and the rendering of a corresponding view in a way that is repeatable, prescriptive, flexible, and testable by default.
public protocol ViewStore<ViewState, Action>: ObservableObject {

    /// A container type for state associated with the corresponding view.
    associatedtype ViewState

    /// Usually represented as an `enum`, `Action` represents any functionality that a view store can perform on-demand.
    associatedtype Action

    /// Single source of truth for state that is used to populate a corresponding view.
    var viewState: ViewState { get }
    
    var publishedViewState: AnyPublisher<ViewState, Never> { get }

    /// Single API for the corresponding view to cause the view store perform some functionality, usually resulting in updated `viewState`.
    /// - Parameter action: The action to perform.
    func send(_ action: Action)
}

/// Default implementation that allows stores with no actions to send to ignore this function requirement in the protocol.
public extension ViewStore {
    func send(_ action: Never) {}
}

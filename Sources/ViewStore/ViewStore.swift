//
//  ViewStore.swift
//  ViewStore
//
//  Created by Michael Liberatore on 5/16/22.
//

import SwiftUI

// A view store allows us to separate view-specific logic and the rendering of that view in a way that is repeatable, prescriptive, flexible, and testable by default.
public protocol ViewStore: ObservableObject {

    // A container type for state associated with the corresponding view.
    associatedtype ViewState

    // Usually represented as an `enum`, `Action` represents any functionality that a view store can perform on-demand.
    associatedtype Action

    // Single source of truth for state that is used to populate a corresponding view.
    var viewState: ViewState { get }

    // Single API for the corresponding view to cause the view store perform some functionality, usually resulting in updated `viewState`.
    func send(_ action: Action)
}

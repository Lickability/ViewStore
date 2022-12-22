//
//  ViewStore.swift
//  ViewStore
//
//  Created by Michael Liberatore on 5/16/22.
//

import SwiftUI
import AsyncAlgorithms
import Clocks
import Combine

/// A view store is an `ObservableObject` that allows us to separate view-specific logic and the rendering of a corresponding view in a way that is repeatable, prescriptive, flexible, and testable by default.
@MainActor
public protocol ViewStore<ViewState, Action>: ObservableObject {

    /// A container type for state associated with the corresponding view.
    associatedtype ViewState

    /// Usually represented as an `enum`, `Action` represents any functionality that a view store can perform on-demand.
    associatedtype Action

    /// Single source of truth for state that is used to populate a corresponding view.
    var viewState: ViewState { get }

    /// Single API for the corresponding view to cause the view store perform some functionality, usually resulting in updated `viewState`.
    /// - Parameter action: The action to perform.
    func send(_ action: Action)
}

/// Default implementation that allows stores with no actions to send to ignore this function requirement in the protocol.
public extension ViewStore {
    func send(_ action: Never) {}
}


protocol Loggable {
    var log: String { get }
}

enum TestAction: Loggable {
    case hello
    
    var log: String {
        return "hello"
    }
}

struct TestViewState {
    let number: Int
}

func hello(store: any ViewStore<TestViewState, TestAction>) {
    
}

@MainActor func test() {
    
    hello(store: TestViewStoreOne())
    
    hello(store: TestViewStoreTwo())
    
    hello(store: AnalyticsViewStore(otherViewStore: TestViewStoreTwo()))

}


//
//final class ABTest<V, A>: ViewStore {
//    let a: any ViewStore<V, A>
//    let b: any ViewStore<V, A>
//    let bucket: Bool
//
//    init(otherViewStore: any ViewStore<V, A>) {
//        self.otherViewStore = otherViewStore
//    }
//
//    var viewState: V {
//        return otherViewStore.viewState
//    }
//
//    func send(_ action: A) {
//
//        let log = action.log
//
//
//        // log this to crashlytics or whatever ^
//
//        otherViewStore.send(action)
//    }
//}

final class AnalyticsViewStore<V, A: Loggable>: ViewStore {
    let otherViewStore: any ViewStore<V, A>
    
    init(otherViewStore: any ViewStore<V, A>) {
        self.otherViewStore = otherViewStore
    }
    
    var viewState: V {
        return otherViewStore.viewState
    }
    
    func send(_ action: A) {
        
        let log = action.log
        
        
        // log this to crashlytics or whatever ^
        
        otherViewStore.send(action)
    }
}

final class TestViewStoreOne: ViewStore {
    
    /// Single source of truth for state that is used to populate a corresponding view.
    var viewState: TestViewState = .init(number: 0)

    /// Single API for the corresponding view to cause the view store perform some functionality, usually resulting in updated `viewState`.
    /// - Parameter action: The action to perform.
    func send(_ action: TestAction) {
        
    }
}

final class TestViewStoreTwo: ViewStore {
    
    /// Single source of truth for state that is used to populate a corresponding view.
    var viewState: TestViewState = .init(number: 1)

    /// Single API for the corresponding view to cause the view store perform some functionality, usually resulting in updated `viewState`.
    /// - Parameter action: The action to perform.
    func send(_ action: TestAction) {
        
    }
}

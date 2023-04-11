//
//  MockStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 12/22/22.
//

import Foundation
import Combine

/// A generic object conforming to `Store` that simply returns the passed-in state. Useful in SwiftUI previews.
public final class MockStore<State, Action>: Store {
    public var publishedState: AnyPublisher<State, Never> {
        return Just(state).eraseToAnyPublisher()
    }
    
    public var state: State
    
    public init(state: State) {
        self.state = state
    }
    
    public func send(_ action: Action) {}
}

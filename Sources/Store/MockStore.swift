//
//  MockStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 12/22/22.
//

import Foundation
import Combine

/// A generic object conforming to `Store` that simply returns the passed-in state. Useful in SwiftUI previews.
public final class MockStore<State: Sendable, Action: Sendable>: Store {
    
    // MARK: - Store

    public var publishedState: AnyPublisher<State, Never> {
        return Just(state).eraseToAnyPublisher()
    }
        
    public var state: State
    
    // MARK: - MockStore
    
    public init(state: State) {
        self.state = state
    }
    
    // MARK: - Store

    public func send(_ action: Action) {}
}

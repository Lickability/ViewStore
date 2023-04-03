//
//  MockViewStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 12/22/22.
//

import Foundation
import Combine

/// A generic object conforming to `ViewStore` that simply returns the passed-in view state. Useful in SwiftUI previews.
public final class MockViewStore<ViewState, Action>: ViewStore {
    public var publishedViewState: AnyPublisher<ViewState, Never> {
        return Just(viewState).eraseToAnyPublisher()
    }
    
     public var viewState: ViewState

     public init(viewState: ViewState) {
         self.viewState = viewState
     }

     public func send(_ action: Action) {}
 }

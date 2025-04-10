//
//  Store+BindingAdditions.swift
//  ViewStore
//
//  Created by Twig on 7/21/22.
//

import SwiftUI
import CasePaths
import Combine

/// An extension on `Store` that provides conveniences for creating `Binding`s.
public extension Store {
    
    @MainActor
    func makeCachedBinding<Value>(key: String, defaultValue: Value, stateKeyPath: KeyPath<State, Value>, actionCasePath: CasePath<Action, Value>) -> Binding<Value> {
        
        if let binding = BindingCache.shared.cache[key] as? Binding<Value> {
            print("HERE 1")
            return binding
        }
        
        let binding = Binding<Value> { [weak self] in
            self?.state[keyPath: stateKeyPath] ?? defaultValue
        } set: { [weak self] value in
            self?.send(actionCasePath.embed(value))
        }
        
        BindingCache.shared.cache[key] = binding
        
        return binding
    }

    /// Provides a mechanism for creating `Binding`s associated with `Action` cases in a `Store`, leveraging `KeyPath`s to reduce duplication and errors. Supports `enum` cases with associated values.
    /// - Parameters:
    ///   - stateKeyPath: The `KeyPath` to the `State` property that this binding wraps.
    ///   - actionCasePath: The `CasePath` to the `Action` case associated with the `State` property.
    func makeBinding<Value>(stateKeyPath: KeyPath<State, Value>, actionCasePath: CasePath<Action, Value>) -> Binding<Value> {
        return .init {
            self.state[keyPath: stateKeyPath]
        } set: { value in
            self.send(actionCasePath.embed(value))
        }
    }

    /// Provides a mechanism for creating `Binding`s associated with `Action` cases in a `Store`, leveraging `KeyPath`s to reduce duplication and errors. Supports `enum` cases without associated values.
    /// - Parameters:
    ///   - stateKeyPath: The `KeyPath` to the `State` property that this binding wraps.
    ///   - actionCasePath: The `CasePath` to the `Action` case associated with the `State` property.
    func makeBinding<Value>(stateKeyPath: KeyPath<State, Value>, actionCasePath: CasePath<Action, Void>) -> Binding<Value> {
        return .init {
            self.state[keyPath: stateKeyPath]
        } set: { value in
            self.send(actionCasePath.embed(()))
        }
    }

    /// Provides a mechanism for creating `Binding<Bool>`s based on the existence of a property on the `State`, leveraging `KeyPath`s to reduce duplication and errors.
    /// - Parameters:
    ///   - stateKeyPath: The `KeyPath` to the optional `State` property whose existence determines the wrapped value.
    ///   - actionCasePath: The `CasePath` to the `Action` case associated with the `State` property.
    func makeBinding<Value>(stateKeyPath: KeyPath<State, Value?>, actionCasePath: CasePath<Action, Void>) -> Binding<Bool> {
        return .init {
            self.state[keyPath: stateKeyPath] != nil
        } set: { value in
            self.send(actionCasePath.embed(()))
        }
    }
    
    /// Provides a mechanism for creating `Binding<Bool>`s based on the existence of a property on the `State`, leveraging `KeyPath`s to reduce duplication and errors.
    /// - Parameters:
    ///   - stateKeyPath: The `KeyPath` to the optional `State` property whose existence determines the wrapped value.
    ///   - actionCasePath: The `CasePath` to the `Action` case associated with the `State` property.
    func makeBinding<Value>(stateKeyPath: KeyPath<State, Value?>, actionCasePath: CasePath<Action, Value?>) -> Binding<Bool> {
        return .init {
            self.state[keyPath: stateKeyPath] != nil
        } set: { value in
            guard !value else {
                return assertionFailure("Unexpectedly received `true` from `makeBinding` Bool convenience setter.")
            }
            
            self.send(actionCasePath.embed(nil))
        }
    }
    
    /// Provides a mechanism for creating `Binding`s that send their value to a `PassthroughSubject`, leveraging `KeyPath`s to reduce duplication and errors.
    /// - Parameters:
    ///   - stateKeyPath: The `KeyPath` to the `State` property that this binding wraps.
    ///   - publisher: The publisher to send the value to.
    func makeBinding<Value>(stateKeyPath: KeyPath<State, Value>, publisher: PassthroughSubject<Value, Never>) -> Binding<Value> {
        return .init {
            self.state[keyPath: stateKeyPath]
        } set: { value in
            publisher.send(value)
        }
    }
    
    /// Provides a mechanism for creating `Binding`s that send their value to a `CurrentValueSubject`, leveraging `KeyPath`s to reduce duplication and errors.
    /// - Parameters:
    ///   - StateKeyPath: The `KeyPath` to the `State` property that this binding wraps.
    ///   - publisher: The publisher to send the value to.
    func makeBinding<Value>(stateKeyPath: KeyPath<State, Value>, publisher: CurrentValueSubject<Value, Never>) -> Binding<Value> {
        return .init {
            self.state[keyPath: stateKeyPath]
        } set: { value in
            publisher.send(value)
        }
    }
}

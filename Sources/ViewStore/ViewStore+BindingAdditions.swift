//
//  ViewStore+BindingAdditions.swift
//  ViewStore
//
//  Created by Twig on 7/21/22.
//

import SwiftUI
import CasePaths

/// An extension on `ViewStore` that provides conveniences for creating `Binding`s.
extension ViewStore {

    /// Provides a mechanism for creating `Binding`s associated with `Action` cases in a `ViewStore`, leveraging `KeyPath`s to reduce duplication and errors. Supports `enum` cases with associated values.
    /// - Parameters:
    ///   - viewStateKeyPath: The `KeyPath` to the `ViewState` property that this binding wraps.
    ///   - actionCasePath: The `CasePath` to the `Action` case associated with the `ViewState` property.
    func makeBinding<Value>(viewStateKeyPath: KeyPath<ViewState, Value>, actionCasePath: CasePath<Action, Value>) -> Binding<Value> {
        return .init {
            self.viewState[keyPath: viewStateKeyPath]
        } set: { value in
            self.send(actionCasePath.embed(value))
        }
    }

    /// Provides a mechanism for creating `Binding`s associated with `Action` cases in a `ViewStore`, leveraging `KeyPath`s to reduce duplication and errors. Supports `enum` cases without associated values.
    /// - Parameters:
    ///   - viewStateKeyPath: The `KeyPath` to the `ViewState` property that this binding wraps.
    ///   - actionCasePath: The `CasePath` to the `Action` case associated with the `ViewState` property.
    func makeBinding<Value>(viewStateKeyPath: KeyPath<ViewState, Value>, actionCasePath: CasePath<Action, Void>) -> Binding<Value> {
        return .init {
            self.viewState[keyPath: viewStateKeyPath]
        } set: { value in
            self.send(actionCasePath.embed(()))
        }
    }

    /// Provides a mechanism for creating `Binding<Bool>`s based on the existence of a property on the `ViewState`, leveraging `KeyPath`s to reduce duplication and errors.
    /// - Parameters:
    ///   - viewStateKeyPath: The `KeyPath` to the optional `ViewState` property whose existence determines the wrapped value.
    ///   - actionCasePath: The `CasePath` to the `Action` case associated with the `ViewState` property.
    func makeBinding<Value>(viewStateKeyPath: KeyPath<ViewState, Value?>, actionCasePath: CasePath<Action, Void>) -> Binding<Bool> {
        return .init {
            self.viewState[keyPath: viewStateKeyPath] != nil
        } set: { value in
            self.send(actionCasePath.embed(()))
        }
    }
}

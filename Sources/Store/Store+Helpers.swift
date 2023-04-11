//
//  Store+Helpers.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/5/23.
//

import Foundation
import Combine

extension Store {
    
    /// Takes a publisher of actions and executes them as they come in
    /// - Parameters:
    ///   - publisher: The publisher of actions to execute as they come in.
    ///   - cancellables: The set of cancellables to store into.
    func pipeActions(publisher: some Publisher<Action, Never>, storingIn cancellables: inout Set<AnyCancellable>) {
        publisher
            .sink { [weak self] in
                self?.send($0)
            }
            .store(in: &cancellables)
    }
}

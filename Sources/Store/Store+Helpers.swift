//
//  Store+Helpers.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/5/23.
//

import Foundation
import Combine

extension Store {
    func pipeActions(publisher: some Publisher<Action, Never>, storingIn cancellables: inout Set<AnyCancellable>) {
        publisher
            .sink { [weak self] in
                self?.send($0)
            }
            .store(in: &cancellables)
    }
}

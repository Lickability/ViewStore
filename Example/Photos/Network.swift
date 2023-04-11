//
//  Network.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine

final class Network {
    
    enum NetworkState {
        case notStarted
        case inProgress
        case finished(Result<Banner, NSError>)
        
        var banner: Banner? {
            switch self {
            case .inProgress, .notStarted:
                return nil
            case .finished(let result):
                return try? result.get()
            }
        }
        
        var error: Error? {
            switch self {
            case .notStarted, .inProgress:
                return nil
            case .finished(let result):
                do {
                    _ = try result.get()
                    return nil
                }
                catch {
                    return error
                }
            }
        }
    }
    
    var publisher: PassthroughSubject<NetworkState, Never> = .init()
    
    func request(banner: Banner) {
        self.publisher.send(.inProgress)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            //self.publisher.send(.finished(.success(banner)))
            
            self.publisher.send(.finished(.failure(.init(domain: "com.viewstore.error", code: 400))))

        }
    
    }
    
    func reset() {
        self.publisher.send(.notStarted)
    }
    
}

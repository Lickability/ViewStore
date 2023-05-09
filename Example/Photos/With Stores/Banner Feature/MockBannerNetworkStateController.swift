//
//  MockBannerNetworkStateController.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine

/// A really contrived fake interface similar to networking state controller for updating `Banner` models on a nonexistent server.
final class MockBannerNetworkStateController {
    
    /// Represents the state of a network request for a banner.
    enum NetworkState {
        
        /// The network request has not started yet.
        case notStarted
        
        /// The network request is currently in progress.
        case inProgress
        
        /// The network request has finished and resulted in either success or failure.
        /// - Parameter Result: A result type containing a `Banner` on success or an `NSError` on failure.
        case finished(Result<Banner, NetworkError>)
        
        /// The `Banner` object obtained from a successful network request, if available.
        var banner: Banner? {
            switch self {
            case .inProgress, .notStarted:
                return nil
            case .finished(let result):
                return try? result.get()
            }
        }
        
        /// The error obtained from a failed network request, if available.
        var error: NetworkError? {
            switch self {
            case .notStarted, .inProgress:
                return nil
            case .finished(let result):
                do {
                    _ = try result.get()
                    return nil
                } catch let error as NetworkError {
                    return error
                } catch {
                    assertionFailure("unhandled error")
                    return nil
                }
            }
        }
        
        /// Possible errors that can occur when using this controller.
        enum NetworkError: LocalizedError {

            /// A mocked error that is expected.
            case intentionalFailure

            // MARK - LocalizedError

            var errorDescription: String? {
                switch self {
                case .intentionalFailure:
                    return "This is an expected error used for testing error handling."
                }
            }
        }
    }

    /// A publisher that sends updates of the `NetworkState`.
    public var publisher: PassthroughSubject<NetworkState, Never> = .init()
    
    /// Uploads a `Banner` to a fake server.
    /// - Parameter banner: The `Banner` to upload.
    func upload(banner: Banner) {
        self.publisher.send(.inProgress)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            // Pick whether you would like to get a successful (`.finished(.success...`) state or any error for this "network request".
            
            //self.publisher.send(.finished(.success(banner)))
            
            self.publisher.send(.finished(.failure(.intentionalFailure)))

        }
    
    }
    
    /// Resets the current networking state to `notStarted`.
    func reset() {
        self.publisher.send(.notStarted)
    }
    
}

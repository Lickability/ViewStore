//
//  BannerUpdateViewStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine
import SwiftUI
import CasePaths

typealias BannerUpdateViewStoreType = Store<BannerUpdateViewStore.State, BannerUpdateViewStore.Action>

/// A `Store` that drives a view that can update a `Banner` through any `BannerDataStoreType`, and exposes view-specific state such as a working copy of the banner, the possible networking error, etc.
final class BannerUpdateViewStore: Store {
    
    // MARK: - Store
    
    /// Represents the state of the `BannerUpdateViewStore`
    struct State: Sendable {
        /// Stores the state of the nested `BannerDataStore`
        let bannerViewState: BannerDataStore.State
        
        /// A working copy of the banner being updated, to be uploaded if the `submit` action is sent.
        let workingCopy: Banner
        
        /// Returns true if the network state is not started or finished, false if it's in progress
        var dismissable: Bool {
            switch bannerViewState.networkState {
            case .notStarted, .finished:
                return true
            case .inProgress:
                return false
            }
        }
        
        /// Returns true if the network state is finished and the result is successful, false otherwise
        var success: Bool {
            switch bannerViewState.networkState {
            case .notStarted, .inProgress:
                return false
            case .finished(let result):
                return (try? result.get()) != nil
            }
        }
        
        // Returns a `NetworkError` if there is an error in the network state when it's finished, otherwise returns nil
        var error: MockBannerNetworkStateController.NetworkState.NetworkError? {
            return bannerViewState.networkState.error
        }
    }
    
    enum Action: Sendable {
        /// Action to update the title of the banner with a given string
        case updateTitle(String)
        
        /// Action to dismiss an error
        case dismissError
        
        /// Action to submit the updated working copy banner to the network
        case submit
    }
    
    @Published var state: State
    var publishedState: AnyPublisher<State, Never> {
        return $state.eraseToAnyPublisher()
    }
    
    // MARK: - BannerUpdateViewStore
    
    private let bannerDataStore: any BannerDataStoreType
    
    private let newTitlePublisher = PassthroughSubject<String, Never>()
        
    /// Creates a new `BannerUpdateViewStore`.
    /// - Parameter bannerDataStore: The data `Store` responsible for updating the banner on the network and its source of truth in the application.
    init(bannerDataStore: any BannerDataStoreType) {
        self.bannerDataStore = bannerDataStore
        
        state = State(bannerViewState: bannerDataStore.state, workingCopy: bannerDataStore.state.banner)
        
        bannerDataStore
            .publishedState
            .combineLatest(newTitlePublisher.map(Banner.init).prepend(state.workingCopy))
            .map { bannerState, workingCopy in
                State(bannerViewState: bannerState, workingCopy: workingCopy)
            }
            .assign(to: &$state)
    }
    
    // MARK: - Store
    
    func send(_ action: Action) {
        switch action {
        case .updateTitle(let title):
            newTitlePublisher.send(title)
        case .submit:
            bannerDataStore.send(.uploadBanner(state.workingCopy))
        case .dismissError:
            bannerDataStore.send(.clearNetworkingState)
        }
    }
    
}

extension BannerUpdateViewStoreType {
    /// Computed property that creates a binding for the working title
    @MainActor
    var workingTitle: Binding<String> {
        makeBinding(stateKeyPath: \.workingCopy.title, actionCasePath: /Action.updateTitle)
    }
    
    /// Computed property that creates a binding for the error presentation state
    @MainActor
    var isErrorPresented: Binding<Bool> {
        .init(get: {
            return self.state.error != nil
        }, set: { _ in
            self.send(.dismissError)
        })
    }
}

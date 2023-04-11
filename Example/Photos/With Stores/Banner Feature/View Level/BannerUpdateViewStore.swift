//
//  BannerUpdateViewStore.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import Combine

typealias BannerUpdateViewStoreType = Store<BannerUpdateViewStore.State, BannerUpdateViewStore.Action>

final class BannerUpdateViewStore: Store {
    
    // MARK: - Store
    
    struct State {
        let bannerViewState: BannerDataStore.State
        
        let workingCopy: Banner
        
        var dismissable: Bool {
            switch bannerViewState.networkState {
            case .notStarted, .finished:
                return true
            case .inProgress:
                return false
            }
        }
        
        var success: Bool {
            switch bannerViewState.networkState {
            case .notStarted, .inProgress:
                return false
            case .finished(let result):
                return (try? result.get()) != nil
            }
        }
        
        var error: NSError? {
            switch bannerViewState.networkState {
            case .notStarted, .inProgress:
                return nil
            case .finished(let result):
                do {
                    _ = try result.get()
                    return nil
                }
                catch {
                    return error as NSError
                }
            }
        }
    }
    
    enum Action {
        case updateTitle(String)
        
        case dismissError
        
        case submit
    }
    
    @Published var state: State
    var publishedState: AnyPublisher<State, Never> {
        return $state.eraseToAnyPublisher()
    }
    
    // MARK: - BannerUpdateViewStore
    
    private let bannerDataStore: any BannerDataStoreType
    
    private let newTitlePublisher = PassthroughSubject<String, Never>()
        
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
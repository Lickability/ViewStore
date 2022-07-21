//
//  ExampleViewStore.swift
//  ViewStore
//
//  Created by Twig on 7/21/22.
//

import SwiftUI
import Combine
import CasePaths

final class ExampleViewStore: ViewStore {
    
    struct ViewState {
        private(set) var navigationTitle = "Cool Title"
        private(set) var isBottomSectionHidden: Bool = false
    }
    
    enum Action {
        case setNavigationTitle(String)
        case toggleBottomSectionHidden(Bool)
    }
    
    @Published private(set) var viewState = ViewState()
    
    var bottomSectionHidden: Binding<Bool> {
        makeBinding(viewStateKeyPath: \.isBottomSectionHidden, actionCasePath: /Action.toggleBottomSectionHidden)
    }

    private let navigationTitlePublisher = PassthroughSubject<String, Never>()
    private let bottomSectionHiddenPublisher = PassthroughSubject<Bool, Never>()
    
    init() {
        setUpViewStatePublisher()
    }
    
    private func setUpViewStatePublisher() {
        let navigationTitlePublisher = navigationTitlePublisher.prepend(viewState.navigationTitle)
        let bottomSectionHiddenPublisher = bottomSectionHiddenPublisher.prepend(viewState.isBottomSectionHidden)
        
        navigationTitlePublisher
            .combineLatest(bottomSectionHiddenPublisher)
            .map { title, bottomSectionHidden in
                ViewState(navigationTitle: title, isBottomSectionHidden: bottomSectionHidden)
            }
            .assign(to: &$viewState)
    }
    
    func send(_ action: Action) {
        switch action {
        case let .setNavigationTitle(title):
            navigationTitlePublisher.send(title)
        case let .toggleBottomSectionHidden(hidden):
            bottomSectionHiddenPublisher.send(hidden)
        }
    }
}

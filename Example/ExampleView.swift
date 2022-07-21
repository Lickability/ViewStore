//
//  ExampleView.swift
//  ViewStore
//
//  Created by Twig on 7/21/22.
//

import SwiftUI

struct ExampleView: View {
    
    @StateObject private var viewStore = ExampleViewStore()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("I am always here.")
                Toggle("Toggle Bottom", isOn: viewStore.bottomSectionHidden)

                Spacer()
                
                Text("I am sometimes here.")
                    .opacity(viewStore.viewState.isBottomSectionHidden ? 0 : 1)
            }
            .navigationTitle(viewStore.viewState.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                viewStore.send(.setNavigationTitle("Updated Title"))
            }
        }
    }
}

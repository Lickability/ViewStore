//
//  PSAUpdateView.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import SwiftUI
import Combine

struct PSAUpdateView<Store: PSAUpdateViewStoreType>: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var store: Store

    init(store: @autoclosure @escaping () -> Store) {
        self._store = StateObject(wrappedValue: store())
    }

    var body: some View {
        VStack {
            TextField("", text: Binding(get: { store.state.workingCopy.title }, set: { string in
                store.send(.updateTitle(string))
            }))
            
            Spacer()
            
            Button {
                store.send(.submit)
            } label: {
                Group {
                    if store.state.dismissable {
                        Text("Submit")
                    } else {
                        ProgressView()
                    }
                }
                .foregroundColor(.white)
                .padding(.vertical, 20)
                .padding(.horizontal, 40)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.blue)
                }
            }
            .disabled(!store.state.dismissable)

        }
        .onChange(of: store.state.success) { success in
            if success { dismiss() }
        }
        .alert(isPresented: .init(get: { return store.state.error != nil }, set: { _ in store.send(.dismissError) }), error: store.state.error) { _ in
            
        } message: { error in
            Text("Error")
        }

    }
}

extension NSError: LocalizedError {
    public var errorDescription: String? {
        return "Hello I am an error"
    }
}

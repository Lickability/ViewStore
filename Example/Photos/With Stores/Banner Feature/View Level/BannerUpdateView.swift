//
//  BannerUpdateView.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import SwiftUI
import Combine

/// A really simple view that allows you to type and upload a new Banner.
struct BannerUpdateView<Store: BannerUpdateViewStoreType>: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var store: Store

    /// Creates a new `BannerUpdateView`.
    /// - Parameter store: The `Store` that drives this view.
    init(store: @autoclosure @escaping () -> Store) {
        self._store = StateObject(wrappedValue: store())
    }

    var body: some View {
        VStack {
            
            VStack {
                Spacer()

                TextField("", text: store.workingTitle)
                    .multilineTextAlignment(.center)
                    .padding(10)
                    .font(.system(size: 36))
                
                Spacer()
            }
            .padding(.horizontal, 30)

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
            .padding(.bottom, 10)
        }
        .onChange(of: store.state.success) { success in
            if success { dismiss() }
        }
        .alert(isPresented: store.isErrorPresented, error: store.state.error) { _ in
            
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

//
//  PhotoList.swift
//  ViewStore
//
//  Created by Twig on 2/24/22.
//

import SwiftUI
import Provider

/// Displays a list of photos retrieved from an API. Uses a `Store` for coordination with the data source.
struct PhotoList<Store: PhotoListViewStoreType>: View {
    
    @StateObject private var store: Store

    /// Creates a new `PhotoList`.
    /// - Parameters:
    ///   - store: The `Store` that drives this view.
    init(store: @autoclosure @escaping () -> Store) {
        self._store = StateObject(wrappedValue: store())
    }

    // MARK: - View

    var body: some View {
        NavigationView {
            ZStack {
                switch store.state.status {
                case .loading:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(x: 2, y: 2)
                case let .content(photos):
                    List {
                        Section {
                            ForEach(photos) { photo in
                                HStack {
                                    AsyncImage(url: photo.thumbnailUrl) { image in
                                        image.resizable()
                                            .aspectRatio(contentMode: .fit)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 150, height: 150)
                                    
                                    Text(photo.title)
                                }
                            }
                        } header: {
                            Toggle("Show Count", isOn: store.showsPhotoCount)
                                .animation(.easeInOut, value: store.state.showsPhotoCount)
                        }
                    }
                case let .error(error):
                    VStack {
                        Image(systemName: "xmark.octagon")
                        Text(error.localizedDescription)
                    }
                }

            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(store.state.navigationTitle)
            .searchable(text: store.searchText, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
}

struct PhotoList_Previews: PreviewProvider {
    static var previews: some View {
        let state = PhotoListViewStore.State(status: .content(MockItemProvider(photosCount: 3).photos))
        
        PhotoList(store: MockStore(state: state))
    }
}

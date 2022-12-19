//
//  PhotoList.swift
//  ViewStore
//
//  Created by Twig on 2/24/22.
//

import SwiftUI
import Provider

/// Displays a list of photos retrieved from an API. Uses a `ViewStore` for coordination with the data source.
struct PhotoList: View {
    
    @StateObject private var store: PhotoListViewStore

    /// Creates a new `PhotoList`.
    /// - Parameters:
    ///   - provider: The provider responsible for fetching photos.
    ///   - scheduler: Determines how state updates are scheduled to be delivered in the view store. Defaults to `default`, which asynchronously schedules updates on the main queue.
    init(provider: Provider, scheduler: MainQueueScheduler = .init(type: .default)) {
        self._store = StateObject(wrappedValue: PhotoListViewStore(provider: provider, scheduler: scheduler))
    }

    // MARK: - View

    var body: some View {
        NavigationView {
            ZStack {
                switch store.viewState.status {
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
                                .animation(.easeInOut, value: store.viewState.showsPhotoCount)
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
            .navigationTitle(store.viewState.navigationTitle)
            .searchable(text: store.searchText, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
}

struct PhotoList_Previews: PreviewProvider {
    static var previews: some View {
        /// use immediate clock here for previews
        PhotoList(provider: MockItemProvider(photosCount: 3), scheduler: .init(type: .synchronous))
    }
}

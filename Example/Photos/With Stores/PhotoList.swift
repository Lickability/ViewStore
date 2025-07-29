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
    
    @Environment(\.isSearching) private var isSearching

    /// Creates a new `PhotoList`.
    /// - Parameters:
    ///   - store: The `Store` that drives this view.
    init(store: @autoclosure @escaping () -> Store) {
        self._store = StateObject(wrappedValue: store())
    }

    // MARK: - View

    var body: some View {
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
                                    Rectangle()
                                        .foregroundStyle(Color.gray)
                                        .frame(width: 150, height: 150)
                                    
                                    Text(photo.title)
                                }
                            }
                        } header: {
                            Toggle("Show Count", isOn: store.showsPhotoCount)
                                .animation(.easeInOut, value: store.state.showsPhotoCount)
                        }
                    }
                    .sheet(isPresented: store.showUpdateView) {
                        BannerUpdateView(store: BannerUpdateViewStore(bannerDataStore: store.bannerDataStore))
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
            .toolbar(content: {
                ToolbarItem(placement: .bottomBar) {
                    Button("Calendar", systemImage: "calendar.circle") {
                        
                    }
                }
                
                ToolbarSpacer(.flexible, placement: .bottomBar)
                
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
            })
            .safeAreaBar(edge: .bottom) {
                if isSearching {
                    BannerView(banner: .init(title: "Check out the new dog photos!"))
                }
            }
    }
}

struct PhotoList_Previews: PreviewProvider {
    static var previews: some View {
        let state = PhotoListViewStore.State(status: .content(MockItemProvider(photosCount: 3).photos))
        
        PhotoList(store: MockStore(state: state))
    }
}

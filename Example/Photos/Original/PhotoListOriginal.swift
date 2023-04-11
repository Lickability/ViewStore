//
//  PhotoListOriginal.swift
//  ViewStore
//
//  Created by Michael Liberatore on 6/13/22.
//

import SwiftUI
import Networking
import Provider
import Combine

/// Displays a list of photos retrieved from an API. Responsible for its own network requests and data coordination.
struct PhotoListOriginal: View {
    @State private var provider: Provider
    @State private var photos: [Photo] = []
    @State private var filteredPhotos: [Photo] = []
    @State private var error: Error?
    @State private var showsPhotoCount = false
    @State private var searchText = ""
    @State private var searchSubject = PassthroughSubject<String, Never>()

    private var debouncedSearchSubject: AnyPublisher<String, Never> {
        return searchSubject.debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Creates a new `PhotoListOriginal`.
    /// - Parameter provider: The provider responsible for fetching photos.
    init(provider: Provider) {
        _provider = State(wrappedValue: provider)
    }

    // MARK: - View
    
    var body: some View {
        NavigationView {
            ZStack {
                if let error = error {
                    VStack {
                        Image(systemName: "xmark.octagon")
                        Text(error.localizedDescription)
                    }
                } else if photos.isEmpty {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(x: 2, y: 2)
                } else {
                    List {
                        Section {
                            ForEach(filteredPhotos) { photo in
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
                            Toggle("Show Count", isOn: $showsPhotoCount)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(showsPhotoCount ? "Photos: \(photos.count)" : "Photos")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: searchText) { newValue in
                searchSubject.send(newValue)
            }
            .onReceive(debouncedSearchSubject) { newValue in
                if newValue.isEmpty {
                    self.filteredPhotos = self.photos
                } else {
                    self.filteredPhotos = self.photos.filter { photo in
                        photo.title.localizedCaseInsensitiveContains(newValue)
                    }
                }
            }
        }
        .task {
            Task {
                provider.provideItems(request: APIRequest.photos, decoder: JSONDecoder(), providerBehaviors: [], requestBehaviors: [], handlerQueue: .main, allowExpiredItems: true) { (result: Result<[Photo], ProviderError>) in
                    switch result {
                    case .success(let photos):
                        self.photos = photos
                        self.filteredPhotos = photos
                        self.error = nil
                    case .failure(let error):
                        self.error = error
                        self.photos = []
                        self.filteredPhotos = []
                    }
                }
            }
        }
    }
}

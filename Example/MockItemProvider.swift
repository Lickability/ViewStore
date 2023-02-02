//
//  MockItemProvider.swift
//  ViewStore
//
//  Created by Michael Liberatore on 7/11/22.
//

import Foundation
import Combine
import Provider
import Persister
import Networking

/// A provider meant to be usable by SwiftUI previews and unit tests to provide mocked, successful `Photo`s synchronously.
final class MockItemProvider: Provider {
    let photos: [Photo]

    /// Creates a new `MockItemProvider` with the specified `Photo`s.
    /// - Parameter photos: the `Photo`s that the provider will "retrieve" synchronously.
    init(photos: [Photo]) {
        self.photos = photos
    }

    /// Creates a new `MockItemProvider` by generating a `Photo` for each `Int` within the range of `(1...photosCount)`.
    /// - Parameter photosCount: The number of photos to generate. Note that the bundle must contain images named with the pattern "thumbnail-x.png" where x can be all values between `1` and `photosCount` (inclusive).
    init(photosCount: Int) {
        self.photos = (1...photosCount).map { index in
            let url = Bundle.main.url(forResource: "thumbnail-\(index)", withExtension: "png")!
            return Photo(albumId: 0, id: index, title: "Hello-\(index)", url: url, thumbnailUrl: url)
        }
    }

    // MARK: - Provider

    func provide<Item>(request: ProviderRequest, decoder: ItemDecoder, providerBehaviors: [ProviderBehavior], requestBehaviors: [RequestBehavior], handlerQueue: DispatchQueue, allowExpiredItem: Bool, itemHandler: @escaping (Result<Item, ProviderError>) -> Void) where Item : Identifiable, Item : Decodable, Item : Encodable {
        itemHandler((photos.first as? Item).flatMap { .success($0) } ?? .failure(.networkError(.noData)))
    }

    func provideItems<Item>(request: ProviderRequest, decoder: ItemDecoder, providerBehaviors: [ProviderBehavior], requestBehaviors: [RequestBehavior], handlerQueue: DispatchQueue, allowExpiredItems: Bool, itemsHandler: @escaping (Result<[Item], ProviderError>) -> Void) where Item : Identifiable, Item : Decodable, Item : Encodable {
        itemsHandler((photos as? [Item]).flatMap { .success($0) } ?? .failure(.networkError(.noData)))
    }

    func provide<Item>(request: ProviderRequest, decoder: ItemDecoder, providerBehaviors: [ProviderBehavior], requestBehaviors: [RequestBehavior], allowExpiredItem: Bool) -> AnyPublisher<Item, ProviderError> where Item : Identifiable, Item : Decodable, Item : Encodable {
        if let item = photos.first as? Item {
            return Just(item)
                .setFailureType(to: ProviderError.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: ProviderError.networkError(.noData))
                .eraseToAnyPublisher()
        }
    }

    func provideItems<Item>(request: ProviderRequest, decoder: ItemDecoder, providerBehaviors: [ProviderBehavior], requestBehaviors: [RequestBehavior], allowExpiredItems: Bool) -> AnyPublisher<[Item], ProviderError> where Item : Identifiable, Item : Decodable, Item : Encodable {
        if let items = photos as? [Item] {
            return Just(items)
                .setFailureType(to: ProviderError.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: ProviderError.networkError(.noData))
                .eraseToAnyPublisher()
        }
    }
}

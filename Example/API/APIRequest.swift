//
//  APIRequest.swift
//  ViewStore
//
//  Created by Twig on 2/24/22.
//

import Foundation
import Provider

/// Represents the requests we can make for content displayed in the app.
enum APIRequest: ProviderRequest {

    /// Fetches albums of placeholder photo models.
    case photos
    
    // MARK: - ProviderRequest

    var persistenceKey: Key? {
        switch self {
        case .photos: return "Photos"
        }
    }

    // MARK: - NetworkRequest
    
    var path: String {
        switch self {
        case .photos:
            return "/photos"
        }
    }
    
    var queryParameters: [URLQueryItem] {
        return [URLQueryItem(name: "_limit", value: "5")]
    }

    var baseURL: URL {
        return URL(string: "https://jsonplaceholder.typicode.com")!
    }
}


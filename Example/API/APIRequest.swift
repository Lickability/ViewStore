//
//  APIRequest.swift
//  ViewStore
//
//  Created by Twig on 2/24/22.
//

import Foundation
import Provider

enum APIRequest: ProviderRequest {
    case posts
    case photos
    
    // MARK: - ProviderRequest

    var persistenceKey: Key? {
        switch self {
        case .photos: return "Photos"
        case .posts: return "Posts"
        }
    }

    // MARK: - NetworkRequest
    
    var path: String {
        switch self {
        case .posts:
            return "/posts"
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


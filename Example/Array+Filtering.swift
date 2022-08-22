//
//  Array+Filtering.swift
//  ViewStore
//
//  Created by Michael Liberatore on 7/13/22.
//

import Foundation

extension Array where Element == Photo {

    /// Filters an array of photos by `searchText` returning only the photos that contain `searchText` in the photo `title` (case insensitive).
    /// - Parameter searchText: The text to query titles for.
    func filter(searchText: String) -> [Photo] {
        guard !searchText.isEmpty else { return self }
        return filter { photo in
            photo.title.localizedCaseInsensitiveContains(searchText)
        }
    }
}

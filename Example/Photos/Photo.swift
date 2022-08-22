//
//  Photo.swift
//  ViewStore
//
//  Created by Twig on 2/24/22.
//

import Foundation
import Provider

/// Represents a remote image.
struct Photo: Codable, Identifiable, Swift.Identifiable {

    /// The unique identifier associated with the album to which this photo belongs.
    let albumId: Int

    /// The unique identifier of this photo.
    let id: Int

    /// Descriptive text that is associated with the image, i.e. what it is called.
    let title: String

    /// The URL at which the full image data can be retrieved.
    let url: URL

    /// THe URL at which a lower resolution version of the image data can be retrieved.
    let thumbnailUrl: URL
    
    // MARK: - Identifiable
    
    var identifier: Key {
        return "\(id)"
    }
}

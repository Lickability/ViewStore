//
//  BindingCache.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/10/25.
//
import SwiftUI

public final class BindingCache {
    @MainActor public static let shared = BindingCache()
    var cache: [String: Any] = [:]

    public init() {
    }
    
}

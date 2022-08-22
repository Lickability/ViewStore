//
//  TestApp.swift
//  ViewStore
//
//  Created by Twig on 2/24/22.
//

import SwiftUI
import Provider
import Networking
import Persister

@main
struct TestApp: App {
    
    @State private var photoProvider: ItemProvider = {
        let controller = NetworkController()
        let diskCache = DiskCache(rootDirectoryURL: FileManager.default.applicationSupportDirectoryURL.appendingPathComponent("Photos"))
        let cache = MemoryCache(capacity: .unlimited, expirationPolicy: .never)
        let persister = Persister(memoryCache: cache, diskCache: diskCache)
        
        return ItemProvider(networkRequestPerformer: controller, cache: persister)
    }()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                PhotoListOriginal(provider: photoProvider)
                    .tabItem {
                        Image(systemName: "photo")
                        Text("Photos (Original)")
                    }
                
                PhotoList(provider: photoProvider)
                    .tabItem {
                        Image(systemName: "photo")
                        Text("Photos")
                    }
            }
        }
    }
}

//
//  HudHudApp.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Nuke
import OSLog
import SwiftLocation
import SwiftUI

// MARK: - HudHudApp

@main
struct HudHudApp: App {

    // MARK: Properties

    @ObservedObject var touchVisualizerManager = TouchManager.shared

    private let mapStore: MapStore
    private let searchStore: SearchViewStore
    private let mapViewStore: MapViewStore
    @State private var isScreenCaptured = UIScreen.main.isCaptured

    // MARK: Computed Properties

    var body: some Scene {
        WindowGroup {
            ContentView(searchStore: self.searchStore, mapViewStore: self.mapViewStore)
                .onAppear {
                    self.touchVisualizerManager.updateVisualizer(isScreenRecording: UIScreen.main.isCaptured)
                }
        }
    }

    // MARK: Lifecycle

    init() {
        let location = Location() // swiftlint:disable:this location_usage
        location.accuracy = .threeKilometers
        self.mapStore = MapStore(userLocationStore: UserLocationStore(location: location))
        let routingStore = RoutingStore(mapStore: self.mapStore)
        self.mapViewStore = MapViewStore(mapStore: self.mapStore, routingStore: routingStore)
        self.searchStore = SearchViewStore(mapStore: self.mapStore, mapViewStore: self.mapViewStore, routingStore: routingStore, filterStore: .shared, mode: .live(provider: .hudhud))

        // Create a custom URLCache to store images on disk
        let diskCache = URLCache(
            memoryCapacity: 100 * 1024 * 1024, // 100 MB memory cache
            diskCapacity: 1000 * 1024 * 1024, // 1 GB disk cache
            diskPath: "sa.hudhud.hudhud.imageCache"
        )

        // Create a DataLoader with custom URLCache
        let dataLoader = DataLoader(configuration: {
            let configuration = URLSessionConfiguration.default
            configuration.urlCache = diskCache
            return configuration
        }())

        // Configure the pipeline with the custom DataLoader and cache
        let pipeline = ImagePipeline {
            $0.dataLoader = dataLoader
            $0.imageCache = ImageCache.shared // Use in-memory cache as well
        }
    }
}

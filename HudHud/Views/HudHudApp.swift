//
//  HudHudApp.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Nuke
import OSLog
import Pulse
import PulseProxy
import SwiftLocation
import SwiftUI
import TypographyKit

// MARK: - HudHudApp

struct HudHudApp: App {

    // MARK: Properties

    @ObservedObject var touchVisualizerManager = TouchManager.shared

    @State var mapStore: MapStore

    private let searchStore: SearchViewStore
    @State private var sheetStore: SheetStore
    @State private var mapViewStore: MapViewStore
    @State private var isScreenCaptured = UIScreen.main.isCaptured

    // MARK: Computed Properties

    var body: some Scene {
        WindowGroup {
            ContentView(
                searchStore: self.searchStore,
                mapViewStore: self.mapViewStore,
                sheetStore: self.sheetStore
            )
            .onAppear {
                self.touchVisualizerManager.updateVisualizer(isScreenRecording: UIScreen.main.isCaptured)
            }
        }
    }

    // MARK: Lifecycle

    init() {
        NetworkLogger.enableProxy()
        let sheetStore = SheetStore(emptySheetType: .search)
        self.sheetStore = sheetStore
        let location = Location() // swiftlint:disable:this location_usage
        location.accuracy = .threeKilometers
        let mapStore = MapStore(userLocationStore: UserLocationStore(location: location))
        let routingStore = RoutingStore(mapStore: mapStore)
        self.mapViewStore = MapViewStore(mapStore: mapStore, sheetStore: sheetStore)
        self.searchStore = SearchViewStore(mapStore: mapStore, sheetStore: sheetStore, routingStore: routingStore, filterStore: .shared, mode: .live(provider: .hudhud))
        self.mapStore = mapStore

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

        ImagePipeline.shared = pipeline

        // Load custom typography configuration
        if let url = Bundle.main.url(forResource: "typography-design-tokens", withExtension: "json") {
            TypographyKit.configure(with: TypographyKitConfiguration.default.setConfigurationURL(url))
        }
    }
}

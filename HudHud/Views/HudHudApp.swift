//
//  HudHudApp.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import APIClient
import Nuke
import OSLog
import Pulse
import SwiftLocation
import SwiftUI
import TypographyKit

// MARK: - AppDpendencies

enum AppDpendencies {
    static let navigationEngine = NavigationEngine(configuration: .default)
    static let locationEngine = LocationEngine()
}

// MARK: - HudHudApp

struct HudHudApp: App {

    // MARK: Properties

    @ObservedObject var touchVisualizerManager = TouchManager.shared
    @State var userLocationStore: UserLocationStore

    // MARK: Computed Properties

    var body: some Scene {
        WindowGroup {
            ContentView(userLocationStore: self.userLocationStore)
                .onAppear {
                    self.touchVisualizerManager.updateVisualizer(isScreenRecording: UIScreen.main.isCaptured)
                }
        }
    }

    // MARK: Lifecycle

    init() {
        let location = Location() // swiftlint:disable:this location_usage
        location.accuracy = .threeKilometers
        self.userLocationStore = UserLocationStore(location: location)

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

        dataLoader.delegate = URLSessionProxyDelegate()

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

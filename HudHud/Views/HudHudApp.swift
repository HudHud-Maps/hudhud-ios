//
//  HudHudApp.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapboxCoreNavigation
import OSLog
import SwiftLocation
import SwiftUI

// MARK: - HudHudApp

@main
struct HudHudApp: App {

    // MARK: Properties

    @ObservedObject var touchVisualizerManager = TouchManager.shared

    private let motionViewModel: MotionViewModel
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
        RouteControllerUserLocationSnappingDistance = DebugStore().userLocationSnappingDistance
        self.motionViewModel = .shared
        let location = Location() // swiftlint:disable:this location_usage
        location.accuracy = .bestForNavigation
        self.mapStore = MapStore(motionViewModel: self.motionViewModel, userLocationStore: UserLocationStore(location: location))
        let routingStore = RoutingStore(mapStore: self.mapStore)
        self.mapViewStore = MapViewStore(mapStore: self.mapStore, routingStore: routingStore)
        self.searchStore = SearchViewStore(mapStore: self.mapStore, mapViewStore: self.mapViewStore, routingStore: routingStore, mode: .live(provider: .hudhud))
    }
}

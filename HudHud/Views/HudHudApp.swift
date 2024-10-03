//
//  HudHudApp.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

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
    private let sheetStore: SheetStore
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
        self.motionViewModel = .shared
        self.sheetStore = SheetStore()
        let location = Location() // swiftlint:disable:this location_usage
        location.accuracy = .bestForNavigation
        self.mapStore = MapStore(motionViewModel: self.motionViewModel, userLocationStore: UserLocationStore(location: location))
        let routingStore = RoutingStore(mapStore: self.mapStore)
        let mapViewStore = MapViewStore(
            mapStore: self.mapStore,
            routingStore: routingStore,
            sheetStore: self.sheetStore
        )
        self.mapViewStore = mapViewStore
        self.searchStore = SearchViewStore(
            mapStore: self.mapStore,
            sheetStore: self.sheetStore,
            routingStore: routingStore,
            mode: .live(provider: .hudhud)
        )
    }
}

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

    private let locationManager = Location() // swiftlint:disable:this location_usage
    private let motionViewModel: MotionViewModel
    private let mapStore: MapStore
    private let searchStore: SearchViewStore
    @State private var isScreenCaptured = UIScreen.main.isCaptured

    // MARK: Computed Properties

    var body: some Scene {
        WindowGroup {
            ContentView(searchStore: self.searchStore)
                .onAppear {
                    self.touchVisualizerManager.updateVisualizer(isScreenRecording: UIScreen.main.isCaptured)
                }
        }
    }

    // MARK: Lifecycle

    init() {
        RouteControllerMaximumDistanceBeforeRecalculating = DebugStore().maximumDistanceBeforeRecalculating
        self.motionViewModel = .shared
        self.mapStore = MapStore(motionViewModel: self.motionViewModel)
        self.searchStore = SearchViewStore(mapStore: self.mapStore, mode: .live(provider: .hudhud))
    }
}

extension Location {

    static let forSingleRequestUsage = {
        assert(Thread.isMainThread)
        let location = Location() // swiftlint:disable:this location_usage
        location.accuracy = .threeKilometers // Location is extremely slow, unless set to this - returns better accuracy none the less.
        return location
    }()

    // Currently not needed, reserved for future use
    static let forContinuesUsage = {
        let location = Location() // swiftlint:disable:this location_usage
        location.accuracy = .threeKilometers
        return location
    }()
}

// MARK: - Location + Previewable

extension Location: Previewable {

    static let storeSetUpForPreviewing = Location() // swiftlint:disable:this location_usage
}

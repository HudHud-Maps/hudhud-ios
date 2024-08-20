//
//  HudHudApp.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import MapboxCoreNavigation
import OSLog
import SwiftUI

// MARK: - HudHudApp

@main
struct HudHudApp: App {

    private let motionViewModel: MotionViewModel
    private let mapStore: MapStore
    private let searchStore: SearchViewStore
    @State private var isScreenCaptured = UIScreen.main.isCaptured
    @ObservedObject var touchVisualizerManager = TouchManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView(searchStore: self.searchStore)
                .onAppear {
                    self.touchVisualizerManager.updateVisualizer(isScreenRecording: UIScreen.main.isCaptured)
                }
        }
    }

    // MARK: - Lifecycle

    init() {
        RouteControllerMaximumDistanceBeforeRecalculating = DebugStore().maximumDistanceBeforeRecalculating
        self.motionViewModel = .shared
        self.mapStore = MapStore(motionViewModel: self.motionViewModel, userLocationStore: UserLocationStore(location: .make()))
        self.searchStore = SearchViewStore(mapStore: self.mapStore, mode: .live(provider: .hudhud))
    }
}

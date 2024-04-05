//
//  HudHudApp.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftLocation
import SwiftUI

@main
struct HudHudApp: App {

	private let locationManager: Location
	private let searchViewStore: SearchViewStore
	private let motionViewModel: MotionViewModel

	var body: some Scene {
		WindowGroup {
			ContentView(locationManager: self.locationManager,
						searchViewStore: self.searchViewStore,
						mapStore: self.searchViewStore.mapStore,
						motionViewModel: self.motionViewModel)
		}
	}

	// MARK: - Lifecycle

	init() {
		self.locationManager = Location()
		self.motionViewModel = MotionViewModel()

		let mapStore = MapStore(motionViewModel: self.motionViewModel)
		self.searchViewStore = SearchViewStore(mapStore: mapStore, mode: .live(provider: .toursprung))
	}
}

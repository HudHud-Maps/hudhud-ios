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
		self.locationManager = .init()
		self.motionViewModel = .init()

		let mapItemStatus = MapItemsStatus(motionViewModel: self.motionViewModel)
		let mapStore = MapStore(mapItemStatus: mapItemStatus)
		self.searchViewStore = .init(mapStore: mapStore, mode: .live(provider: .toursprung))
	}

}

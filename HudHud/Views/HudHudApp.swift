//
//  HudHudApp.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftLocation
import SwiftUI

// MARK: - HudHudApp

@main
struct HudHudApp: App {

	private let locationManager = Location() // swiftlint:disable:this location_usage
	private let motionViewModel: MotionViewModel
	private let mapStore: MapStore
	private let searchStore: SearchViewStore

	var body: some Scene {
		WindowGroup {
			ContentView(searchStore: self.searchStore)
//				.environmentObject(self.locationManager)
		}
	}

	// MARK: - Lifecycle

	init() {
		self.motionViewModel = .shared
		self.mapStore = MapStore(motionViewModel: self.motionViewModel)
		self.searchStore = SearchViewStore(mapStore: self.mapStore, mode: .live(provider: .toursprung))
	}
}

extension Location {

	static let forSingleRequestUsage = {
		assert(Thread.isMainThread)
		return Location()
	}()

	// Currently not needed, reserved for future use
//	static let forContinuesUsage = Location()
}

// MARK: - Location + Previewable

extension Location: Previewable {

	static let preview = Location() // swiftlint:disable:this location_usage
}

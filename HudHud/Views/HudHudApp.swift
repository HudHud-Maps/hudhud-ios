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

	var body: some Scene {
		WindowGroup {
			let mapStore = MapStore(motionViewModel: MotionViewModel())
			let searchStore = SearchViewStore(mapStore: mapStore, mode: .live(provider: .toursprung))

			ContentView(locationManager: self.locationManager, searchStore: searchStore)
				.environmentObject(self.locationManager)
		}
	}
}

extension Location: ObservableObject {}

// MARK: - Location + Preview

extension Location: Preview {

	static let preview = Location() // swiftlint:disable:this location_usage
}

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

	// TODO: Lets use one Location Instance in the whole app, add as environment object to WindowGroup
	private let locationManager: Location

	var body: some Scene {
		WindowGroup {
			ContentView(locationManager: self.locationManager)
		}
	}

	// MARK: - Lifecycle

	init() {
		self.locationManager = Location()
	}
}

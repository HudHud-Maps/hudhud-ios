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

	private let locationManager = Location()

	var body: some Scene {
		WindowGroup {
			ContentView(locationManager: self.locationManager,
						searchViewStore: .init(mode: .live(provider: .toursprung)))
		}
	}
}

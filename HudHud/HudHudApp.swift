//
//  HudHudApp.swift
//  HudHud
//
//  Created by Patrick Kladek on 29.01.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import SwiftUI
import Firebase

@main
struct HudHudApp: App {

	init() {
		FirebaseApp.configure()
	}
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
}

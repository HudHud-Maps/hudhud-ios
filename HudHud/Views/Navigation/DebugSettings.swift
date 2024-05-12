//
//  DebugSettings.swift
//  HudHud
//
//  Created by Alaa . on 12/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation

class DebugSettings: ObservableObject {
	@Published var routingURL: String = "gh.maptoolkit.net" {
		didSet {
			if !self.isValidHostname(self.routingURL) {
				self.routingURL = oldValue // Revert to the old value if new value is invalid
			}
		}
	}

	@Published var isURLValid: Bool = true

	@Published var simulateRide: Bool = false

	// MARK: - Internal

	func isValidHostname(_ hostname: String) -> Bool {
		let hostnameRegex = "^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,6}$"
		return NSPredicate(format: "SELF MATCHES %@", hostnameRegex).evaluate(with: hostname)
	}

}

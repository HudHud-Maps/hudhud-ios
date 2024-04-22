//
//  LoggerSettings.swift
//  HudHud
//
//  Created by Fatima Aljaber on 07/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import OSLog

extension Logger {
	private static var subsystem = Bundle.main.bundleIdentifier! // swiftlint:disable:this force_unwrapping

	static let searchView = Logger(subsystem: subsystem, category: "SearchView")
	static let POIData = Logger(subsystem: subsystem, category: "POIData")
	static let toursprung = Logger(subsystem: subsystem, category: "Toursprung")
	static let routing = Logger(subsystem: subsystem, category: "Routing")
	static let mapInteraction = Logger(subsystem: subsystem, category: "MapInteraction")
}

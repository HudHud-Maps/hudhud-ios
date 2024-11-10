//
//  LoggerSettings.swift
//  HudHud
//
//  Created by Fatima Aljaber on 07/03/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import os

typealias Logger = os.Logger // we dont need to import OSLog everyehere in the app

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier! // swiftlint:disable:this force_unwrapping

    static let searchView = Logger(subsystem: subsystem, category: "SearchView")
    static let poiData = Logger(subsystem: subsystem, category: "POIData")
    static let routing = Logger(subsystem: subsystem, category: "Routing")
    static let mapInteraction = Logger(subsystem: subsystem, category: "MapInteraction")
    static let streetView = Logger(subsystem: subsystem, category: "StreetView")
    static let sheet = Logger(subsystem: subsystem, category: "Sheet")
    static let mapButtons = Logger(subsystem: subsystem, category: "mapButtons")
    static let navigationPath = Logger(subsystem: subsystem, category: "navigationPath")
    static let notificationAuth = Logger(subsystem: subsystem, category: "notificationAuth")
    static let navigationViewRating = Logger(subsystem: subsystem, category: "navigationViewRating")
    static let currentLocation = Logger(subsystem: subsystem, category: "currentLocation")
    static let streetViewScene = Logger(subsystem: subsystem, category: "streetViewScene")
    static let panoramaView = Logger(subsystem: subsystem, category: "panoramaView")
    static let userRegistration = Logger(subsystem: subsystem, category: "userRegistration")
    static let diagnostics = Logger(subsystem: subsystem, category: "Diagnostics")
    static let locationEngine = Logger(subsystem: subsystem, category: "LocationEngine")
}

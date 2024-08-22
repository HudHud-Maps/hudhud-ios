//
//  DebugStore.swift
//  HudHud
//
//  Created by Alaa . on 12/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import MapboxCoreNavigation
import OSLog
import SwiftUI

class DebugStore: ObservableObject {

    // MARK: Properties

    @AppStorage("routingHost") var routingHost: String = "gh.map.dev.hudhud.sa"
    @AppStorage("baseurl") var baseURL: String = "https://api.dev.hudhud.sa"
    @AppStorage("SFSymbolsMap") var customMapSymbols: Bool?
    @AppStorage("RouteControllerMaximumDistanceBeforeRecalculating") var maximumDistanceBeforeRecalculating: CLLocationDistance = RouteControllerMaximumDistanceBeforeRecalculating

    // MARK: Computed Properties

    @Published var simulateRide: Bool = UIApplication.environment == .development {
        didSet {
            Logger.routing.notice("simulate ride: \(self.simulateRide)")
        }
    }
}

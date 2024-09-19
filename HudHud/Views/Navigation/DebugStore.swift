//
//  DebugStore.swift
//  HudHud
//
//  Created by Alaa . on 12/05/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import Foundation
import OSLog
import SwiftUI

class DebugStore: ObservableObject {

    @AppStorage("routingHost") var routingHost: String = "gh.map.dev.hudhud.sa"
    @AppStorage("baseurl") var baseURL: String = "https://api.dev.hudhud.sa"
    @AppStorage("SFSymbolsMap") var customMapSymbols: Bool?

    @AppStorage("simulateRide") var simulateRide: Bool = UIApplication.environment == .development
}

//
//  RoutingService.swift
//  HudHud
//
//  Created by Ali Hilal on 29/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import FerrostarCoreFFI
import Foundation

protocol RoutingService {
    func calculateRoute(
        from start: Waypoint,
        to end: Waypoint,
        passingBy waypoints: [Waypoint]
    ) async throws -> [Route]
}

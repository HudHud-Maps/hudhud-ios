//
//  RoutePlanner.swift
//  HudHud
//
//  Created by Ali Hilal on 29/10/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation
import FerrostarCoreFFI
import Foundation

// MARK: - RoutePlanner

final class RoutePlanner {

    // MARK: Properties

    private let routingService: RoutingService

    // MARK: Lifecycle

    init(routingService: RoutingService) {
        self.routingService = routingService
    }

    // MARK: Functions

    func planRoutes(from start: Waypoint, to end: Waypoint, waypoints: [Waypoint] = []) async throws -> [Route] {
        guard start.coordinate.clLocationCoordinate2D.isValid, end.coordinate.clLocationCoordinate2D.isValid else {
            throw RoutingError.routing(.invalidInput(message: "Invalid input coordinates."))
        }

        return try await self.routingService.calculateRoute(from: start, to: end, passingBy: waypoints)
    }
}

// MARK: - Extensions

extension CLLocationCoordinate2D {
    var isValid: Bool {
        return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
    }
}

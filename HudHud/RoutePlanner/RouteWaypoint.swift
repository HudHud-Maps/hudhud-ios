//
//  RouteWaypoint.swift
//  HudHud
//
//  Created by Patrick Kladek on 07.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import BackendService
import Foundation

typealias DestinationPointOfInterest = ResolvedItem

// MARK: - RouteWaypoint

struct RouteWaypoint: Hashable {

    // MARK: Nested Types

    enum RouteWaypointType: Hashable {
        case userLocation(Coordinates)
        case location(DestinationPointOfInterest)
    }

    // MARK: Properties

    let type: RouteWaypointType
    let title: String
}

//
//  PathTraversalProgress.swift
//  HudHud
//
//  Created by Ali Hilal on 12/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

struct PathTraversalProgress {

    // MARK: Properties

    let totalDistance: CLLocationDistance
    let drivenDistance: CLLocationDistance
    let lastPosition: ExactRoutePosition
    let drivenCoordinates: [CLLocationCoordinate2D]
    let remainingCoordinates: [CLLocationCoordinate2D]

    // MARK: Computed Properties

    var percentageComplete: Double {
        (self.drivenDistance / self.totalDistance) * 100
    }
}

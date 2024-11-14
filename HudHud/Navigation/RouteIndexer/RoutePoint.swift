//
//  RoutePoint.swift
//  HudHud
//
//  Created by Ali Hilal on 12/11/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CoreLocation

struct RoutePoint {
    let index: Int
    let coordinate: CLLocationCoordinate2D
    let distanceFromStart: Double
    let bearingToNext: Double?
}

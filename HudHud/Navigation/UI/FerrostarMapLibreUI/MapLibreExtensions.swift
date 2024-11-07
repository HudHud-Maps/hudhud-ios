//
//  MapLibreExtensions.swift
//  HudHud
//
//  Created by Ali Hilal on 03.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import FerrostarCore
import Foundation
import MapLibre

extension NavigationState {
    var routePolyline: MLNPolyline {
        MLNPolylineFeature(coordinates: routeGeometry.map(\.clLocationCoordinate2D))
    }

    var remainingRoutePolyline: MLNPolyline {
        MLNPolylineFeature(coordinates: routeGeometry.map(\.clLocationCoordinate2D))
    }
}

//
//  MapViewCamera.swift
//  HudHud
//
//  Created by Patrick Kladek on 12.05.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import MapLibreSwiftUI

public extension MapViewCamera {
    var isTrackingUserLocationWithCourse: Bool {
        if case .trackingUserLocationWithCourse = state {
            return true
        }
        return false
    }

    static func automotiveNavigation(zoom: Double = 18.0, pitch: Double = 45.0) -> MapViewCamera {
        MapViewCamera.trackUserLocationWithCourse(
            zoom: zoom,
            pitch: pitch
        )
    }
}

extension MapViewCamera {

    var zoom: Double? {
        switch self.state {
        case let .centered(_, zoom, _, _, _):
            return zoom
        case let .trackingUserLocation(zoom, _, _, _):
            return zoom
        case let .trackingUserLocationWithCourse(zoom, _, _):
            return zoom
        case let .trackingUserLocationWithHeading(zoom, _, _):
            return zoom
        default:
            return nil
        }
    }
}
